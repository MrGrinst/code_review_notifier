require "sqlite3"
require_relative "./cipher.rb"

class DB
  def self.db
    @db ||= begin
              db = SQLite3::Database.new(File.expand_path("~/.code_review_notifier/data.db"))
              migrate_if_needed(db)
              db
            end
  end

  def self.migrate_if_needed(db)
    db.execute("CREATE TABLE IF NOT EXISTS code_change_activity_notified (id VARCHAR(50) PRIMARY KEY, notified_at TIMESTAMP);")
    db.execute("CREATE TABLE IF NOT EXISTS settings (key VARCHAR(50) PRIMARY KEY, value TEXT, salt TEXT);")
  end

  def self.execute(sql)
    db.execute(sql)
  end

  def self.query_single_row(sql)
    db.execute(sql) do |row|
      return row
    end
    return nil
  end

  def self.save_setting(key, value, is_secret:)
    salt = "NULL"
    if is_secret
      salt, encrypted = Cipher.encrypt(value)
      salt = "'#{salt}'"
      value = encrypted
    end
    db.execute("DELETE FROM settings WHERE key = '#{key}';")
    db.execute("INSERT INTO settings (key, value, salt) VALUES('#{key}', '#{value}', #{salt});")
  end

  def self.get_setting(key)
    row = query_single_row("SELECT value, salt FROM settings WHERE key = '#{key}'")
    if row && row[1]
      Cipher.decrypt(row[0], row[1])
    elsif row
      row[0]
    end
  end
end

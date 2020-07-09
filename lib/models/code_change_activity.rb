require "rubiclifier"

MESSAGES_TO_IGNORE = [/Uploaded patch set 1/, /Build Started/, /owns \d+% of/]
AUTHOR_TRANSLATIONS = {
  "Service Cloud Jenkins" => "Jenkins",
  /\w+ Gergich \(Bot\)/ => "Gergich"
}

class CodeChangeActivity
  attr_reader :id, :author, :is_self, :message, :created_at, :code_change

  def initialize(id, author, is_self, message, created_at, code_change)
    @id = id
    @author = CodeChangeActivity.translate_author(author)
    @is_self = is_self
    @message = CodeChangeActivity.translate_message(message)
    @created_at = created_at
    @code_change = code_change
  end

  def notified
    Rubiclifier::DB.execute("INSERT INTO code_change_activity_notified (id, notified_at) VALUES('#{id}', CURRENT_TIMESTAMP);")
  end

  def should_notify?
    !is_self &&
      code_change.activity_from_self_at && created_at > code_change.activity_from_self_at &&
      MESSAGES_TO_IGNORE.none? { |m| message.match(m) } &&
      !Rubiclifier::DB.query_single_row("SELECT id FROM code_change_activity_notified WHERE id = '#{id}'")
  end

  def self.translate_author(author)
    AUTHOR_TRANSLATIONS.keys.each do |pattern|
      author.sub!(pattern, AUTHOR_TRANSLATIONS[pattern])
    end
    author
  end

  def self.translate_message(message)
    message.sub(/^Patch Set \d+:\s+/, "")
           .gsub("'", %q(\\\\\\\\'))
           .gsub("\n", " ")
           .gsub("  ", " ")
           .gsub(">", "")
           .sub(/^\(/, "\\(")
           .sub(/^\[/, "\\[")
           .sub(/^-/, "\\-")
  end
end

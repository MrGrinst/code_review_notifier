require "rubiclifier"
require "byebug"

class CodeChangeActivity
  attr_reader :id, :author, :is_self, :message, :created_at, :code_change

  def notified
    if id
      Rubiclifier::DB.execute("INSERT INTO code_change_activity_notified (id, notified_at) VALUES('#{id}', CURRENT_TIMESTAMP);")
    end
  end

  def should_notify?
    !is_self &&
      (code_change.activity_from_self_at && created_at > code_change.activity_from_self_at && code_change.includes_self || message == "just opened merge request") &&
      messages_to_ignore.none? { |m| message.match(m) } &&
      !Rubiclifier::DB.query_single_row("SELECT id FROM code_change_activity_notified WHERE id = '#{id}'")
  end

  def messages_to_ignore
    raise NotImplementedError
  end
end

require "rubiclifier"
require_relative "./code_change_activity.rb"

class GitlabCodeChangeActivity < CodeChangeActivity
  def initialize(id, author, is_self, message, created_at, code_change)
    @id = id
    @author = author
    @is_self = is_self
    @message = GitlabCodeChangeActivity.translate_message(message)
    @created_at = created_at
    @code_change = code_change
  end

  def messages_to_ignore
    [/^marked the task .* as (completed|incomplete)$/, /^changed the description$/, /^resolved all threads$/]
  end

  def self.translate_message(message)
    message = message.gsub("'", "’")
      .gsub("\n", " ")
      .gsub("  ", " ")
      .gsub(">", "")
      .sub(/^\(/, "\\(")
      .sub(/^\[/, "\\[")
      .sub(/^-/, "\\-")
    if message =~ /added \d+ commits/
      "pushed code or rebased"
    else
      message
    end
  end
end

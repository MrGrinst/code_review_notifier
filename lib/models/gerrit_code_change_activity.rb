require "rubiclifier"
require_relative "./code_change_activity.rb"

AUTHOR_TRANSLATIONS = {
  "Service Cloud Jenkins" => "Jenkins",
  /\w+ Gergich \(Bot\)/ => "Gergich"
}

class GerritCodeChangeActivity < CodeChangeActivity
  def initialize(id, author, is_self, message, created_at, code_change)
    @id = id
    @author = CodeChangeActivity.translate_author(author)
    @is_self = is_self
    @message = CodeChangeActivity.translate_message(message)
    @created_at = created_at
    @code_change = code_change
  end

  def messages_to_ignore
    [/Uploaded patch set 1/, /Build Started/, /owns \d+% of/]
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

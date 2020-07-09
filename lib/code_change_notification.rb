require "rubiclifier"
require_relative "./api.rb"

class CodeChangeNotification
  attr_reader :code_change_activity
  private :code_change_activity

  def initialize(code_change_activity)
    @code_change_activity = code_change_activity
  end

  def send
    code_change = code_change_activity.code_change
    id = code_change.id
    owner = code_change.owner
    subject = code_change.subject

    message = code_change_activity.message
    author = code_change_activity.author
    Rubiclifier::Notification.new(
      author,
      message,
      "#{owner}: #{subject}",
      Api.current_api.favicon,
      Api.current_api.code_change_url(code_change)
    ).send
  end
end

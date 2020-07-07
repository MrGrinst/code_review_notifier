require_relative './api.rb'

class Notifier
  def self.notify(code_change_activity)
    code_change = code_change_activity.code_change
    id = code_change.id
    owner = code_change.owner
    subject = code_change.subject

    message = code_change_activity.message
    author = code_change_activity.author
    system("terminal-notifier -title '#{author}' -subtitle '#{owner}: #{subject}' -message '#{message}' -appIcon #{Api.current_api.favicon} -open '#{Api.current_api.code_change_url(code_change)}'")
  end
end

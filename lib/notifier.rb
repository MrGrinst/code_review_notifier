require_relative "./api.rb"

class Notifier
  def self.notify_about_code_change(code_change_activity)
    code_change = code_change_activity.code_change
    id = code_change.id
    owner = code_change.owner
    subject = code_change.subject

    message = code_change_activity.message
    author = code_change_activity.author
    notify(author, message, "#{owner}: #{subject}", Api.current_api.favicon, Api.current_api.code_change_url(code_change))
  end

  def self.notify(title, message, subtitle = nil, icon = nil, url = nil)
    args = {
      "title" => title,
      "message" => message,
      "subtitle" => subtitle,
      "appIcon" => icon,
      "open" => url
    }
    all_args = args.keys.reduce("") do |arg_string, key|
      if args[key]
        arg_string += " -#{key} '#{args[key]}'"
      end
      arg_string
    end
    system("/usr/local/bin/terminal-notifier #{all_args}")
  end
end

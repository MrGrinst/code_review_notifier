require "io/console"
require_relative "./api.rb"
require_relative "./notifier.rb"

SECONDS_BETWEEN_RUNS = 90
SECONDS_BETWEEN_NOTIFICATIONS = 5

class CodeReviewNotifier
  def self.setup(args)
    system("mkdir -p ~/.code_review_notifier")
    system("brew bundle --file #{File.expand_path(File.dirname(__FILE__) + "/..")}/Brewfile")

    if args[0] == "--setup"
      print("What's the base URL? (i.e. https://gerrit.google.com) ")
      DB.save_setting("base_api_url", STDIN.gets.chomp, is_secret: false)

      print("What's the account username? ")
      DB.save_setting("username", STDIN.gets.chomp, is_secret: false)

      print("What's the account password? (hiding input) ")
      DB.save_setting("password", STDIN.noecho(&:gets).chomp, is_secret: true)
      puts

      print("What's the account id? (check #{Api.current_api.base_api_url}/settings/) ")
      DB.save_setting("account_id", STDIN.gets.chomp, is_secret: false)

      puts("All setup!")
      puts
      puts("It's recommended that you set this up as a system service with serviceman. Check it out here: https://git.rootprojects.org/root/serviceman")
      puts("Set code_review_notifier to run on startup with `serviceman add --name code_review_notifier code_review_notifier`")
      exit
    end

    if !Api.current_api.is_setup?
      Notifier.notify("Missing Setup Info", "Run `code_review_notifier --setup` to setup.")
      puts
      puts("You must finish setup first by running with the `--setup` option.")
      puts("`code_review_notifier --setup`")
      exit
    end
  end

  def self.call(args)
    setup(args)

    while true
      is_first_run = is_first_run?
      puts
      puts("Querying API...")
      all_code_changes = Api.current_api.all_code_changes
      puts("Checking for notifications to display...")
      all_activity = []
      all_code_changes.each do |cc|
        activity_for_code_change = cc.code_change_activity
        activity_for_code_change.sort! { |a, b| a.created_at <=> b.created_at }
        cc.activity_from_self_at = activity_for_code_change.find { |a| a.is_self }&.created_at
        all_activity.concat(activity_for_code_change)
      end
      all_activity.select(&:should_notify?).each do |code_change_activity|
        code_change_activity.notified
        unless is_first_run
          puts("Notifying of change!")
          Notifier.notify_about_code_change(code_change_activity)
          sleep(SECONDS_BETWEEN_NOTIFICATIONS)
        end
      end
      sleep(SECONDS_BETWEEN_RUNS)
    end
  end

  def self.is_first_run?
    DB.query_single_row("SELECT id FROM code_change_activity_notified;").nil?
  end
end

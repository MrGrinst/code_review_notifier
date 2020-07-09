require "rubiclifier"
require_relative "./api.rb"
require_relative "./code_change_notification.rb"

SECONDS_BETWEEN_RUNS = 90
SECONDS_BETWEEN_NOTIFICATIONS = 5

class CodeReviewNotifier < Rubiclifier::BaseApplication
  def show_help
    puts
    puts("This polls for updates to patch sets/pull requests and notifies you about any relevant changes.")
    puts
    puts("Usage:")
    puts("  code_review_notifier --help  | Shows this help menu")
    puts("  code_review_notifier --setup | Runs setup")
    puts("  code_review_notifier         | Start listening for changes (should be run in background)")
    puts
    exit
  end

  def run_application
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
          CodeChangeNotification.new(code_change_activity).send
          sleep(SECONDS_BETWEEN_NOTIFICATIONS)
        end
      end
      sleep(SECONDS_BETWEEN_RUNS)
    end
  end

  def not_setup
    Rubiclifier::Notification.new(
      "Missing Setup Info",
      "Run `code_review_notifier --setup` to setup."
    ).send
  end

  def features
    [
      Rubiclifier::Feature::BACKGROUND,
      Rubiclifier::Feature::DATABASE,
      Rubiclifier::Feature::NOTIFICATIONS
    ]
  end

  def settings
    @settings ||= [
      Rubiclifier::Setting.new("base_api_url", "base URL", explanation: "e.g. https://gerrit.google.com"),
      Rubiclifier::Setting.new("username", "account username"),
      Rubiclifier::Setting.new("password", "account password", explanation: "input hidden", is_secret: true),
      Rubiclifier::Setting.new("account_id", "account ID", explanation: -> {"check #{Api.current_api.base_api_url}/settings/"})
    ]
  end

  def executable_name
    "code_review_notifier"
  end

  def data_directory
    "~/.code_review_notifier"
  end

  def migrations_location
    "#{File.expand_path(File.dirname(__FILE__) + "/..")}/migrations.rb"
  end

  def is_first_run?
    Rubiclifier::DB.query_single_row("SELECT id FROM code_change_activity_notified;").nil?
  end
end

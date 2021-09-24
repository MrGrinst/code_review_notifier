require "rubiclifier"
require_relative "./api.rb"
require_relative "./code_change_notification.rb"

SECONDS_BETWEEN_RUNS = 60
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
    $stdout.sync = true
    while true
      unless Rubiclifier::IdleDetector.is_idle?
        is_first_run = is_first_run?
        puts
        puts(Time.now().to_s)
        puts("Querying API...")
        all_code_changes = Api.current_api.all_code_changes
        puts("Checking for notifications to display...")
        all_activity = []
        all_code_changes.each do |cc|
          cc.code_change_activity.sort! { |a, b| a.created_at <=> b.created_at }
          all_activity.concat(cc.code_change_activity)
        end
        all_activity.select(&:should_notify?).each do |code_change_activity|
          code_change_activity.notified
          unless is_first_run
            puts("Notifying of change!")
            CodeChangeNotification.new(code_change_activity).send
            sleep(SECONDS_BETWEEN_NOTIFICATIONS)
          end
        end
        puts("Sleeping for #{SECONDS_BETWEEN_RUNS} seconds...")
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
      Rubiclifier::Feature::IDLE_DETECTION,
      Rubiclifier::Feature::NOTIFICATIONS
    ]
  end

  def settings
    @settings ||= [
      Rubiclifier::Setting.new("base_api_url", "base URL", explanation: "e.g. https://gerrit.google.com"),
      Rubiclifier::Setting.new("api_token", "API token"),
      Rubiclifier::Setting.new("username", "Gitlab username"),
      Rubiclifier::Setting.new("team_name", "Gitlab team")
    ]
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

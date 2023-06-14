require "rubiclifier"
require "graphql/client"
require "graphql/client/http"
require "byebug"
require_relative "./models/code_change.rb"
require_relative "./models/gitlab_code_change_activity.rb"

class StoredValues
  def self.base_api_url
    @base_api_url ||= Rubiclifier::DB.get_setting("base_api_url")
  end

  def self.username
    @username ||= Rubiclifier::DB.get_setting("username")
  end

  def self.team_name
    @team_name ||= Rubiclifier::DB.get_setting("team_name")
  end

  def self.api_token
    @password ||= Rubiclifier::DB.get_setting("api_token")
  end
end

class GitlabApi < Rubiclifier::BaseApi
  Rubiclifier::Feature.set_enabled([Rubiclifier::Feature::DATABASE])
  Rubiclifier::DB.hydrate("~/.code_review_notifier", "#{File.expand_path(File.dirname(__FILE__) + "/..")}/migrations.rb")

  HTTP = GraphQL::Client::HTTP.new(StoredValues.base_api_url) do
    def headers(context)
      { "Authorization": "Bearer #{StoredValues.api_token}" }
    end
  end

  Schema = GraphQL::Client.load_schema(HTTP)

  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

  OpenMrCommentQuery = Client.parse <<-"GRAPHQL"
  query {
    group(fullPath: "#{StoredValues.team_name}") {
      groupMembers {
        nodes {
          user {
            name
            username
            openMRs: assignedMergeRequests(state: opened) {
              nodes {
                createdAt
                headPipeline {
                  updatedAt
                  status
                }
                participants {
                  nodes {
                    username
                  }
                }
                approved
                title
                project {
                  group {
                    path
                  }
                  name
                }
                id
                webUrl
                discussions {
                  nodes {
                    notes {
                      nodes {
                        body
                        system
                        createdAt
                        id
                        author {
                          username
                          name
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  GRAPHQL

  MergedMrCommentQuery = Client.parse <<-"GRAPHQL"
  query($mergedAfter: Time) {
    group(fullPath: "#{StoredValues.team_name}") {
      groupMembers {
        nodes {
          user {
            name
            username
            mergedMRs: assignedMergeRequests(state: merged, mergedAfter: $mergedAfter) {
              nodes {
                createdAt
                headPipeline {
                  updatedAt
                  status
                }
                participants {
                  nodes {
                    username
                  }
                }
                approved
                title
                project {
                  group {
                    path
                  }
                  name
                }
                id
                webUrl
              }
            }
          }
        }
      }
    }
  }
  GRAPHQL

  def self.invalid_credentials_error
    Rubiclifier::Notification.new(
      "Incorrect Credentials",
      "Trying running `code_review_notifier --setup` again."
    ).send
    sleep(120)
    exit
  end

  def self.all_code_changes
    open_mr_query = Client.query(OpenMrCommentQuery)
    open_mrs = open_mr_query.data.group.group_members.nodes.flat_map { |n| n.user.open_m_rs.nodes.map { |n2| {user: n.user.name, username: n.user.username, mr: n2 } } }
    merged_mr_query = Client.query(MergedMrCommentQuery, variables: {mergedAfter: Time.now - 61})
    merged_mrs = merged_mr_query.data.group.group_members.nodes.flat_map { |n| n.user.merged_m_rs.nodes.map { |n2| {user: n.user.name, username: n.user.username, mr: n2 } } }
    merged_mrs = merged_mrs.map { |mr| code_change_from_graphql(mr[:mr], mr[:user], mr[:username], true) }
    open_mrs = open_mrs.map { |mr| code_change_from_graphql(mr[:mr], mr[:user], mr[:username], false) }
    open_mrs.concat(merged_mrs)
  end

  def self.code_change_from_graphql(data, name, username, is_merged)
    includes_self = data.participants.nodes.map { |p| p.username }.include?(StoredValues.username)
    code_change = CodeChange.new(data.id, name, "#{data.project.group&.path}/#{data.project.name}", data.title, data.web_url, data.head_pipeline&.updated_at && Time.parse(data.head_pipeline&.updated_at), data.head_pipeline&.status, data.approved, is_merged, username == StoredValues.username, includes_self)
    if is_merged
      code_change.code_change_activity = [
        GitlabCodeChangeActivity.new("#{data.id}-merged-placeholder", name, true, "placeholder", Time.now() - 10000, code_change),
        GitlabCodeChangeActivity.new("#{data.id}-merged", name, false, "merged", Time.now(), code_change)
      ]
    else
      messages = data.discussions.nodes.flat_map { |n| n.notes.nodes }
      code_change.code_change_activity = messages
        .map { |m| code_change_activity_from_json(code_change, m) }
        .reject do |a|
          message = a.message.downcase.strip
          hide_for_me = message =~ /pushed code or rebased/
          hide_for_all = message.start_with?("aborted the automatic merge") || message.start_with?("enabled an automatic merge")
          hide_for_all || (a.is_self && hide_for_me)
        end
      code_change.generate_additional_activity
    end
    code_change.persist
    code_change
  end

  def self.code_change_activity_from_json(code_change, message)
    GitlabCodeChangeActivity.new(message.id, message.author.name, message.author.username == StoredValues.username, message.body, Time.parse(message.created_at), code_change)
  end

  def self.favicon
    "https://about.gitlab.com/images/press/logo/png/gitlab-icon-rgb.png"
  end

  def self.code_change_url(code_change)
    code_change.web_url
  end
end

require_relative "./base_api.rb"
require_relative "./models/code_change.rb"
require_relative "./models/code_change_activity.rb"

class GerritApi < BaseApi
  def self.authenticate
    res = post("/login/", {
      body: "username=#{username}&password=#{URI.escape(password)}&rememberme=1",
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
      },
      follow_redirects: false
    })
    @token = res.headers["set-cookie"].match("GerritAccount=(.*?);")[1]
    raise "Your username or password is incorrect. Trying running `code_review_notifier --setup` again." if @token.nil?
  end

  def self.all_code_changes
    wrap_with_authentication do
      get("/changes/?S=0&q=is%3Aopen%20owner%3Aself%20-is%3Awip%20-is%3Aignored%20limit%3A25&q=is%3Aopen%20owner%3Aself%20is%3Awip%20limit%3A25&q=is%3Aopen%20-owner%3Aself%20-is%3Awip%20-is%3Aignored%20reviewer%3Aself%20limit%3A25&q=is%3Aclosed%20-is%3Aignored%20%28-is%3Awip%20OR%20owner%3Aself%29%20%28owner%3Aself%20OR%20reviewer%3Aself%29%20-age%3A4w%20limit%3A10&o=DETAILED_ACCOUNTS&o=MESSAGES", {
        headers: {
          "Cookie" => "GerritAccount=#{@token};"
        }
      })
    end.parsed_response.flat_map { |js| js.map { |j| code_change_from_json(j) } }
  end

  def self.code_change_from_json(json)
    code_change = CodeChange.new(json["_number"].to_s, json["owner"]["name"], json["project"], json["subject"], Time.parse(json["updated"]).to_i)
    code_change.code_change_activity = json["messages"].map { |m| code_change_activity_from_json(code_change, m) }
    code_change
  end

  def self.code_change_activity_from_json(code_change, json)
    CodeChangeActivity.new(json["id"].to_s, json["author"]["name"], json["author"]["_account_id"].to_s == account_id, json["message"], Time.parse(json["date"]), code_change)
  end

  def self.favicon
    "#{base_api_url}/favicon.ico"
  end

  def self.code_change_url(code_change)
    "#{base_api_url}/c/#{code_change.id}"
  end
end

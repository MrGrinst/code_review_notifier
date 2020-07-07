require "httparty"
require_relative "./gerrit_api.rb"

class HTTParty::Parser
  def json
    JSON.parse(body.gsub(")]}'", ""))
  end
end

class BaseApi
  include HTTParty

  def self.authenticate
    raise NotImplementedError
  end

  def self.all_code_changes
    raise NotImplementedError
  end

  def self.favicon
    raise NotImplementedError
  end

  def self.code_change_url(code_change)
    raise NotImplementedError
  end

  def self.wrap_with_authentication(&block)
    res = block.call
    if res.code == 401 || res.code == 403
      self.authenticate
      block.call
    else
      res
    end
  end

  def self.is_setup?
    base_api_url && username && password && account_id
  end

  def self.base_api_url
    @base_api_url ||= begin
                        url = DB.get_setting("base_api_url")
                        base_uri(url)
                        url
                      end
  end

  def self.username
    @username ||= DB.get_setting("username")
  end

  def self.password
    @password ||= DB.get_setting("password")
  end

  def self.account_id
    @account_id ||= DB.get_setting("account_id")
  end
end

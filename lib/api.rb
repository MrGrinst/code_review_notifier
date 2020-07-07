require_relative "./gerrit_api.rb"

class Api
  def self.current_api
    GerritApi
  end
end

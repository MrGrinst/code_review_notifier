require_relative "./gitlab_api.rb"

class Api
  def self.current_api
    GitlabApi
  end
end

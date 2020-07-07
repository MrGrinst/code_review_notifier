require "date"
require_relative "../database.rb"

class CodeChange
  attr_accessor :code_change_activity
  attr_reader :id, :owner, :project, :subject, :updated_at
  attr_writer :activity_from_self_at

  def initialize(id, owner, project, subject, updated_at)
    @id = id
    @owner = owner
    @project = project
    @subject = subject.gsub("'", "")
    @updated_at = updated_at
  end

  def activity_from_self_at
    raise "@activity_from_self_at is not set" unless instance_variable_defined?("@activity_from_self_at")
    @activity_from_self_at
  end
end

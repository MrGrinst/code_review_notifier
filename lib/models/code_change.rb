require "date"

class CodeChange
  attr_accessor :code_change_activity
  attr_reader :id, :owner, :project, :subject, :updated_at

  def initialize(id, owner, project, subject, updated_at)
    @id = id
    @owner = owner
    @project = project
    @subject = subject.gsub("'", "’")
    @updated_at = updated_at
  end

  def activity_from_self_at
    @activity_from_self_at ||= code_change_activity.find { |a| a.is_self }&.created_at
  end
end

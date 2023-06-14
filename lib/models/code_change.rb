require "date"

class CodeChange
  attr_accessor :code_change_activity
  attr_reader :id, :owner, :project, :subject, :pipeline_updated_at, :last_pipeline_updated_at, :is_self, :includes_self,
              :pipeline_status, :last_pipeline_status, :last_approval_status, :approved, :web_url, :is_merged

  def initialize(id, owner, project, subject, web_url = nil, pipeline_updated_at = nil, pipeline_status = nil, approved = nil, is_merged = nil, is_self = nil, includes_self = nil)
    @id = id
    @owner = owner
    @is_merged = is_merged
    @project = project
    @subject = subject.gsub("'", "’")
    @web_url = web_url
    @pipeline_updated_at = pipeline_updated_at
    @pipeline_status = pipeline_status
    @approved = approved
    row = Rubiclifier::DB.query_single_row("SELECT pipeline_updated_at, last_approval_status, last_pipeline_status FROM code_change WHERE id = '#{id}'") || [Time.now().to_s, approved, pipeline_status]
    @last_approval_status = row[1] == 1
    @last_pipeline_status = row[2]
    @last_pipeline_updated_at = row[0] == "" ? Time.now() : Time.parse(row[0])
    @is_self = is_self
    @includes_self = includes_self
  end

  def activity_from_self_at
    @activity_from_self_at ||= code_change_activity.find { |a| a.is_self }&.created_at
  end

  def generate_additional_activity
    if is_self
      @code_change_activity.push(GitlabCodeChangeActivity.new("#{id}-placeholder", owner, true, "placeholder", Time.now() - 100000, self))
    end
    if !is_merged
      @code_change_activity.push(GitlabCodeChangeActivity.new("#{id}-opened", owner, is_self, "just opened merge request", Time.now(), self))
    end
    if pipeline_updated_at && pipeline_updated_at > last_pipeline_updated_at && pipeline_status != last_pipeline_status
      if pipeline_status != "CREATED" && pipeline_status != "PENDING" && pipeline_status != "RUNNING" && (is_self || pipeline_status != "FAILED")
        @code_change_activity.push(GitlabCodeChangeActivity.new(nil, "Gitlab", false, "pipeline status: #{pipeline_status}", Time.now(), self))
      end
    end
    if approved != last_approval_status
      if is_self || !approved
        @code_change_activity.push(GitlabCodeChangeActivity.new(nil, "Gitlab", false, approved ? "fully approved" : "needs approvals again", Time.now(), self))
      end
    end
  end

  def persist
    if Rubiclifier::DB.query_single_row("SELECT id FROM code_change WHERE id = '#{id}'")
      Rubiclifier::DB.execute("UPDATE code_change SET pipeline_updated_at = '#{pipeline_updated_at.to_s}', last_pipeline_status = '#{pipeline_status}', last_approval_status = #{approved} WHERE id = '#{id}';")
    else
      Rubiclifier::DB.execute("INSERT INTO code_change (id, pipeline_updated_at, last_pipeline_status, last_approval_status) VALUES('#{id}', '#{pipeline_updated_at.to_s}', '#{pipeline_status}', #{approved});")
    end
  end
end

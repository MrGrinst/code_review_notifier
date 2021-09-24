migrations = []
migrations << <<SQL
  CREATE TABLE IF NOT EXISTS code_change_activity_notified (
    id VARCHAR(50) PRIMARY KEY,
    notified_at TIMESTAMP
  );
SQL
migrations << <<SQL
  CREATE TABLE IF NOT EXISTS code_change (
    id VARCHAR(50) PRIMARY KEY,
    pipeline_updated_at TIMESTAMP,
    last_pipeline_status VARCHAR(25),
    last_approval_status BOOLEAN
  );
SQL
migrations

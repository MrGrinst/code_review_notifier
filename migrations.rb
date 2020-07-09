migrations = []
migrations << <<SQL
  CREATE TABLE IF NOT EXISTS code_change_activity_notified (
    id VARCHAR(50) PRIMARY KEY,
    notified_at TIMESTAMP
  );
SQL
migrations

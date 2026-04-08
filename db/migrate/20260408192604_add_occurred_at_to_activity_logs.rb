class AddOccurredAtToActivityLogs < ActiveRecord::Migration[8.1]
  def up
    add_column :activity_logs, :occurred_at, :datetime
    ActivityLog.update_all("occurred_at = created_at")
    change_column_null :activity_logs, :occurred_at, false
  end

  def down
    remove_column :activity_logs, :occurred_at
  end
end

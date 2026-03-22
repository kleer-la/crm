class ChangeActivityLogUserIdNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :activity_logs, :user_id, true
  end
end

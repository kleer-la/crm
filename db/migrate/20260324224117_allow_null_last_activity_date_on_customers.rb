class AllowNullLastActivityDateOnCustomers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :customers, :last_activity_date, true
  end
end

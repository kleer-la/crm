class AllowNullDateBecameCustomer < ActiveRecord::Migration[8.1]
  def change
    change_column_null :customers, :date_became_customer, true
  end
end

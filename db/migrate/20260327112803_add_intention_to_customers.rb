class AddIntentionToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :intention, :integer
  end
end

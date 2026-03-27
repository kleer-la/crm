class RenameIntentionToStrategyOnCustomers < ActiveRecord::Migration[8.1]
  def change
    rename_column :customers, :intention, :strategy
  end
end

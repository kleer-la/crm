class RemoveFinalValueFromProposals < ActiveRecord::Migration[8.1]
  def change
    remove_column :proposals, :final_value, :decimal
  end
end

class AddDescriptionToProposals < ActiveRecord::Migration[8.1]
  def change
    add_column :proposals, :description, :text, null: false, default: ""
    reversible do |dir|
      dir.up { execute "UPDATE proposals SET description = title WHERE description = ''" }
    end
  end
end

class AddFollowUpFromToProposals < ActiveRecord::Migration[8.1]
  def change
    add_column :proposals, :follow_up_from, :date
  end
end

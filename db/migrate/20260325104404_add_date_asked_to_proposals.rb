class AddDateAskedToProposals < ActiveRecord::Migration[8.1]
  def change
    add_column :proposals, :date_asked, :date
  end
end

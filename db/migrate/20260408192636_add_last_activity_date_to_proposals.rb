class AddLastActivityDateToProposals < ActiveRecord::Migration[8.1]
  def up
    add_column :proposals, :last_activity_date, :date
    execute <<~SQL
      UPDATE proposals
      SET last_activity_date = COALESCE(
        (SELECT DATE(MAX(al.created_at))
         FROM activity_logs al
         WHERE al.loggable_type = 'Proposal'
           AND al.loggable_id = proposals.id),
        DATE(proposals.created_at)
      )
    SQL
  end

  def down
    remove_column :proposals, :last_activity_date
  end
end

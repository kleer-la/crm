class BackfillProposalLastActivityDate < ActiveRecord::Migration[8.1]
  def up
    # Sent / Under Review → use date_sent as the client-facing activity date
    execute <<~SQL
      UPDATE proposals
      SET last_activity_date = date_sent
      WHERE status IN (1, 2)  -- sent, under_review
        AND date_sent IS NOT NULL
        AND (last_activity_date IS NULL OR last_activity_date < date_sent)
    SQL

    # Won / Lost / Cancelled → use actual_close_date
    execute <<~SQL
      UPDATE proposals
      SET last_activity_date = actual_close_date
      WHERE status IN (3, 4, 5)  -- won, lost, cancelled
        AND actual_close_date IS NOT NULL
        AND (last_activity_date IS NULL OR last_activity_date < actual_close_date)
    SQL
  end

  def down
    # Irreversible — no way to know which were backfilled vs naturally set
    raise ActiveRecord::IrreversibleMigration
  end
end

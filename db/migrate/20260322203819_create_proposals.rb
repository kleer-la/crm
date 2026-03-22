class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals do |t|
      t.string :title, null: false
      t.references :linkable, polymorphic: true, null: false
      t.integer :status, default: 0, null: false
      t.decimal :estimated_value, precision: 12, scale: 2
      t.decimal :final_value, precision: 12, scale: 2
      t.date :date_sent
      t.date :expected_close_date
      t.date :actual_close_date
      t.text :win_loss_reason
      t.text :notes
      t.string :current_document_url
      t.references :responsible_consultant, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :proposals, :status
    add_index :proposals, :expected_close_date
  end
end

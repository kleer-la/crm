class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :company_name, null: false
      t.string :industry
      t.integer :status, default: 0, null: false
      t.decimal :total_revenue, precision: 12, scale: 2, default: 0
      t.date :date_became_customer, null: false
      t.date :last_activity_date, null: false
      t.references :responsible_consultant, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :customers, :company_name, unique: true
    add_index :customers, :status
  end
end

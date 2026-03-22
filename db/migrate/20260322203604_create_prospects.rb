class CreateProspects < ActiveRecord::Migration[8.1]
  def change
    create_table :prospects do |t|
      t.string :company_name, null: false
      t.string :primary_contact_name, null: false
      t.string :primary_contact_email, null: false
      t.string :primary_contact_phone
      t.string :industry
      t.integer :source
      t.integer :status, default: 0, null: false
      t.decimal :estimated_value, precision: 12, scale: 2
      t.text :disqualification_reason
      t.integer :converted_customer_id
      t.references :responsible_consultant, null: false, foreign_key: { to_table: :users }
      t.date :date_added, null: false
      t.date :last_activity_date, null: false

      t.timestamps
    end

    add_index :prospects, :company_name, unique: true
    add_index :prospects, :primary_contact_email, unique: true
    add_index :prospects, :status
    add_index :prospects, :converted_customer_id
  end
end

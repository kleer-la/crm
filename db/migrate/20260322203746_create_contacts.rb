class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :role_title
      t.boolean :primary, default: false, null: false
      t.references :customer, null: false, foreign_key: true

      t.timestamps
    end

    add_index :contacts, :email
  end
end

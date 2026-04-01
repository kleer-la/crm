class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.integer :platform, null: false
      t.string :external_contact_id, null: false
      t.string :contact_name
      t.integer :status, default: 0, null: false
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :conversations, [ :platform, :external_contact_id ], unique: true
    add_index :conversations, :status
    add_index :conversations, :last_message_at
  end
end

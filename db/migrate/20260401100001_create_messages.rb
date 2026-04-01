class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.integer :direction, null: false
      t.text :content
      t.integer :message_type, default: 0, null: false
      t.string :external_message_id
      t.datetime :sent_at, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :messages, :external_message_id, unique: true
    add_index :messages, :sent_at
  end
end

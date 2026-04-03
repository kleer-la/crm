class CreateConversationReadStates < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_read_states do |t|
      t.references :user, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.datetime :last_read_at, null: false

      t.timestamps
    end

    add_index :conversation_read_states, [:user_id, :conversation_id], unique: true, name: "index_conversation_read_states_uniqueness"
  end
end

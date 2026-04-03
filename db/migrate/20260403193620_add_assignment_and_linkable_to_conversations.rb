class AddAssignmentAndLinkableToConversations < ActiveRecord::Migration[8.1]
  def change
    add_reference :conversations, :assigned_user, null: true, foreign_key: { to_table: :users }
    add_column :conversations, :linkable_type, :string
    add_column :conversations, :linkable_id, :bigint
    add_index :conversations, [:linkable_type, :linkable_id], name: "index_conversations_on_linkable"
  end
end

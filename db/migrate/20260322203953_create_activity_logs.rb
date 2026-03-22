class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :loggable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.integer :entry_type, null: false
      t.integer :touchpoint_type
      t.text :content, null: false

      t.timestamps
    end

    add_index :activity_logs, :created_at
  end
end

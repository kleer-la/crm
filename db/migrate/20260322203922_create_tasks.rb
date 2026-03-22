class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.references :linkable, polymorphic: true, null: false
      t.references :assigned_to, null: false, foreign_key: { to_table: :users }
      t.date :due_date, null: false
      t.integer :priority, default: 1, null: false
      t.integer :status, default: 0, null: false
      t.text :cancellation_reason
      t.datetime :completed_at
      t.text :notes

      t.timestamps
    end

    add_index :tasks, :due_date
    add_index :tasks, :status
    add_index :tasks, :priority
  end
end

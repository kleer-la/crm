class CreateConsultantAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :consultant_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assignable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :consultant_assignments, [ :user_id, :assignable_type, :assignable_id ], unique: true, name: "idx_consultant_assignments_uniqueness"
  end
end

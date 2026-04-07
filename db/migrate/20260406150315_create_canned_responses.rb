class CreateCannedResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :canned_responses do |t|
      t.string :name, null: false
      t.text :content, null: false
      t.string :key
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :canned_responses, :key, unique: true, where: "key IS NOT NULL"
    add_index :canned_responses, :position
  end
end

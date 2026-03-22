class CreateDocumentVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :document_versions do |t|
      t.string :label, null: false
      t.string :url, null: false
      t.references :proposal, null: false, foreign_key: true
      t.references :archived_by, null: false, foreign_key: { to_table: :users }
      t.datetime :archived_at, null: false

      t.timestamps
    end
  end
end

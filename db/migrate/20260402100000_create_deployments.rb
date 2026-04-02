class CreateDeployments < ActiveRecord::Migration[8.1]
  def change
    create_table :deployments do |t|
      t.string :version
      t.string :commit_sha, null: false
      t.string :commit_url
      t.text :commit_message
      t.string :author
      t.string :branch
      t.string :environment
      t.datetime :deployed_at, null: false
      t.string :deployed_by

      t.timestamps
    end

    add_index :deployments, :deployed_at, unique: true
    add_index :deployments, :commit_sha
  end
end

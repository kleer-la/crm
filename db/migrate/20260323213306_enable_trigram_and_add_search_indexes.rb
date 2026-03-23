class EnableTrigramAndAddSearchIndexes < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_trgm"

    add_index :prospects, :company_name, using: :gin, opclass: :gin_trgm_ops, name: "index_prospects_on_company_name_trgm"
    add_index :customers, :company_name, using: :gin, opclass: :gin_trgm_ops, name: "index_customers_on_company_name_trgm"
    add_index :proposals, :title, using: :gin, opclass: :gin_trgm_ops, name: "index_proposals_on_title_trgm"
  end
end

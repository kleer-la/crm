class AddCountryToCustomersAndProspects < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :country, :string
    add_column :prospects, :country, :string
  end
end

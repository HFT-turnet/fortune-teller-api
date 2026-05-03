class AddCountryToCases < ActiveRecord::Migration[8.1]
  def change
    add_column :cases, :country, :string, after: :sex
  end
end

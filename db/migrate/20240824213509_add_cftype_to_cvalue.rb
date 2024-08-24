class AddCftypeToCvalue < ActiveRecord::Migration[7.1]
  def change
    add_column :cvalues, :cf_type, :integer, :after => :inflation
  end
end

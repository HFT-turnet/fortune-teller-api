class AddCsliceIdToCvalue < ActiveRecord::Migration[7.1]
  def change
    add_column :cvalues, :cslice_id, :integer, :after => :case_id
  end
end

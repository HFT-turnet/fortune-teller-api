class AddLabelToCslice < ActiveRecord::Migration[7.1]
  def change
    add_column :cslices, :label, :string, :after => :id
    add_column :cslices, :cvaluetype, :integer, :after => :id
  end
end

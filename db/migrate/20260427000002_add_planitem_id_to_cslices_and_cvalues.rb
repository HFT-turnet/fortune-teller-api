class AddPlanitemIdToCslicesAndCvalues < ActiveRecord::Migration[8.0]
  def change
    add_column :cslices, :planitem_id, :integer, after: :case_id
    add_column :cvalues, :planitem_id, :integer, after: :case_id
    add_index :cslices, :planitem_id
    add_index :cvalues, :planitem_id
  end
end

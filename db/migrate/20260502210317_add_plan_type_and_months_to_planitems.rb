class AddPlanTypeAndMonthsToPlanitems < ActiveRecord::Migration[7.0]
  def change
    add_column :planitems, :plan_type, :integer, after: :category
    add_column :planitems, :months, :integer, after: :trailt
  end
end

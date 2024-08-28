class AddNodeleteToCases < ActiveRecord::Migration[7.1]
  def change
    add_column :cases, :nodelete, :boolean, :after => :sex
  end
end

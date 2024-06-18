class CreateCases < ActiveRecord::Migration[7.1]
  def change
    create_table :cases do |t|
      t.string :external_id
      t.integer :byear
      t.integer :dyear
      t.integer :sex
      t.timestamps
    end
  end
end

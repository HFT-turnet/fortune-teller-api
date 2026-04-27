class CreatePlanitems < ActiveRecord::Migration[8.0]
  def change
    create_table :planitems do |t|
      t.integer :case_id, null: false
      t.string :title
      t.integer :category
      t.integer :fromt
      t.integer :tot
      t.integer :leadt
      t.integer :trailt

      t.timestamps
    end
    add_index :planitems, :case_id
    add_foreign_key :planitems, :cases
  end
end

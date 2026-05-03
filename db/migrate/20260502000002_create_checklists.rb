class CreateChecklists < ActiveRecord::Migration[8.0]
  def change
    create_table :checklists do |t|
      t.integer :case_id, null: false
      t.integer :planitem_id
      t.text :text
      t.string :flow_ref
      t.integer :status, null: false, default: 1

      t.timestamps
    end
    add_index :checklists, :case_id
    add_index :checklists, :planitem_id
    add_foreign_key :checklists, :cases
    add_foreign_key :checklists, :planitems
  end
end

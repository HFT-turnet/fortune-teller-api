class CreateChecklists < ActiveRecord::Migration[8.0]
  def change
    create_table :checklists do |t|
      t.bigint :case_id, null: false
      t.bigint :planitem_id
      t.text :text
      t.string :flow_ref
      t.integer :status, null: false, default: 1

      t.timestamps
    end
    add_index :checklists, :case_id
    add_index :checklists, :planitem_id
    add_foreign_key :checklists, :cases, column: :case_id
    add_foreign_key :checklists, :planitems
  end
end

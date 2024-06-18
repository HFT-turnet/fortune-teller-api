class CreateSimulations < ActiveRecord::Migration[7.1]
  def change
    create_table :simulations do |t|
      t.integer :case_id
      t.integer :valuetype
      t.integer :sourcetype
      t.integer :sourceid
      t.integer :t
      t.decimal :value, precision: 14, scale: 2
      t.timestamps
    end
  end
end

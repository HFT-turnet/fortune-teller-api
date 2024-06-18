class CreateCvalues < ActiveRecord::Migration[7.1]
  def change
    create_table :cvalues do |t|
      t.integer :case_id
      t.integer :t
      t.integer :cvaluetype
      t.string :label
      t.decimal :cto, precision: 14, scale: 2
      t.decimal :ev, precision: 14, scale: 2
      t.integer :fromt
      t.integer :tot
      t.decimal :interest, precision: 6, scale: 4
      t.decimal :inflation, precision: 6, scale: 4
      t.timestamps
    end
  end
end

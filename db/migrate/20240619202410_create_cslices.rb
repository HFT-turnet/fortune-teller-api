class CreateCslices < ActiveRecord::Migration[7.1]
  def change
    create_table :cslices do |t|
      t.integer :case_id
      t.integer :t
      t.decimal :i, precision: 6, scale: 4
      t.string :disclaimer
      t.string :source
      t.string :info
      t.timestamps
    end
  end
end

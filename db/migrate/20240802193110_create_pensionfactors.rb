class CreatePensionfactors < ActiveRecord::Migration[7.1]
  def change
    create_table :pensionfactors do |t|
      t.string :ptype
      t.string :provider
      t.string :factor
      t.string :subgroup
      t.integer :year
      t.decimal :value, precision: 10, scale: 2
    end
  end
end

class DropPersistaccounts < ActiveRecord::Migration[7.0]
  def change
    drop_table :persistaccounts do |t|
      t.string :randname, null: false
      t.string :password_digest
      t.date :lastaction
      t.timestamps

      t.index :randname, unique: true
    end
  end
end
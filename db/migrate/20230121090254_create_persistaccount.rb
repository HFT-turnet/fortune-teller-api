class CreatePersistaccount < ActiveRecord::Migration[7.0]
  # This is the equivalent of a User Model, but we do not want to know anything about the persistenceholder.
  def change
    create_table :persistaccounts do |t|
      t.string :randname, null: false # a column to contain a randomly generatet identifier shown to the user of the api.
      t.string :password_digest # this is not obligatory, as users may choose to save the data without password.
      t.date :lastaction # to be able to archive accounts
      t.timestamps
    end
    add_index :persistaccounts, :randname, unique: true
  end
end

class CreateApiKeys < ActiveRecord::Migration[7.0]
  #Note the bearer_id and bearer_type columns, instead of a user_id column. We're going to be defining a polymorphic API key model, meaning not just a User can have an API key. 
  def change
    create_table :api_keys do |t|
      t.integer :bearer_id, null: false
      t.string :bearer_type, null: false
      t.string :token_digest, null: false
      t.timestamps
    end
    add_index :api_keys, [:bearer_id, :bearer_type]
    add_index :api_keys, :token_digest, unique: true
  end
end

class DropApiKeys < ActiveRecord::Migration[7.0]
  def change
    drop_table :api_keys do |t|
      t.integer :bearer_id, null: false
      t.string :bearer_type, null: false
      t.string :token_digest, null: false
      t.timestamps

      t.index %i[bearer_id bearer_type]
      t.index :token_digest, unique: true
    end
  end
end
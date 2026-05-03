class AddChatActiveToCases < ActiveRecord::Migration[8.0]
  def change
    add_column :cases, :chat_active, :boolean, after: :nodelete
  end
end

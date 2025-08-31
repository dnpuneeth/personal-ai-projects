class AddCachedToAiEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :ai_events, :cached, :boolean, default: false, null: false
  end
end

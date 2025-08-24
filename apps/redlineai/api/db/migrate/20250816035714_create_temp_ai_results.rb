class CreateTempAiResults < ActiveRecord::Migration[7.1]
  def change
    create_table :temp_ai_results do |t|
      t.references :document, null: false, foreign_key: true
      t.string :event_type, null: false
      t.json :result_data, null: false
      t.boolean :cached, default: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :temp_ai_results, :expires_at
    add_index :temp_ai_results, [:document_id, :event_type]
  end
end

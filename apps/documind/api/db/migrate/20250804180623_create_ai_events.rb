class CreateAiEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_events do |t|
      t.references :document, null: false, foreign_key: true
      t.string :event_type
      t.string :model
      t.integer :tokens_used
      t.integer :latency_ms
      t.integer :cost_cents
      t.jsonb :metadata

      t.timestamps
    end
  end
end

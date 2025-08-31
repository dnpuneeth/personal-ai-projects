class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :document, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :title, null: false
      t.integer :message_count, default: 0, null: false
      t.integer :total_tokens_used, default: 0, null: false
      t.integer :total_cost_cents, default: 0, null: false
      t.datetime :last_message_at
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :conversations, :expires_at
    add_index :conversations, [:document_id, :user_id]
    add_index :conversations, :last_message_at

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :role, null: false # 'user' or 'assistant'
      t.text :content, null: false
      t.jsonb :metadata, default: {}
      t.integer :tokens_used, default: 0
      t.integer :cost_cents, default: 0
      t.timestamps
    end

    add_index :messages, :role
    add_index :messages, :created_at
  end
end

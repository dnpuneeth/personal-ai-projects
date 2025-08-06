class CreateDeletedDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :deleted_documents do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :original_document_id, null: false
      t.string :title, null: false
      t.string :file_type
      t.integer :page_count, default: 0
      t.integer :chunk_count, default: 0
      t.integer :total_cost_cents, default: 0
      t.integer :total_tokens_used, default: 0
      t.integer :ai_events_count, default: 0
      t.datetime :deleted_at, null: false

      t.timestamps
    end
    
    add_index :deleted_documents, :deleted_at
    add_index :deleted_documents, :original_document_id
  end
end

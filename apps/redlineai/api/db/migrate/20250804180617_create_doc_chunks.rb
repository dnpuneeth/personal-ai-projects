class CreateDocChunks < ActiveRecord::Migration[8.0]
  def change
    create_table :doc_chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.text :content
      t.integer :chunk_index
      t.integer :start_token
      t.integer :end_token
      # Vector field will be added in production with pgvector extension
      # t.column :embedding, :vector, limit: 1536

      t.timestamps
    end

    add_index :doc_chunks, :chunk_index
    # Vector index will be added in production
    # add_index :doc_chunks, :embedding, using: :ivfflat, with: {lists: 100}
  end
end

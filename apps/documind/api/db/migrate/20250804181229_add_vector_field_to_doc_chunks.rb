class AddVectorFieldToDocChunks < ActiveRecord::Migration[8.0]
  def up
    # Only add vector field if pgvector extension is available
    if extension_enabled?('vector')
      execute "ALTER TABLE doc_chunks ADD COLUMN embedding vector(1536)"
      add_index :doc_chunks, :embedding, using: :ivfflat, opclass: { embedding: :vector_l2_ops }
    end
  end

  def down
    if column_exists?(:doc_chunks, :embedding)
      remove_index :doc_chunks, :embedding if index_exists?(:doc_chunks, :embedding)
      remove_column :doc_chunks, :embedding
    end
  end

  private

  def extension_enabled?(extension_name)
    ActiveRecord::Base.connection.execute(
      "SELECT 1 FROM pg_extension WHERE extname = '#{extension_name}'"
    ).any?
  end
end

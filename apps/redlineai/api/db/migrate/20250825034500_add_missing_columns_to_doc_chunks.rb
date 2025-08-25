class AddMissingColumnsToDocChunks < ActiveRecord::Migration[8.0]
  def change
    # Add missing columns that should have been created in the original migration
    unless column_exists?(:doc_chunks, :chunk_index)
      add_column :doc_chunks, :chunk_index, :integer
      add_index :doc_chunks, :chunk_index
    end
    
    unless column_exists?(:doc_chunks, :start_token)
      add_column :doc_chunks, :start_token, :integer
    end
    
    unless column_exists?(:doc_chunks, :end_token)
      add_column :doc_chunks, :end_token, :integer
    end
  end
end

class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :title
      t.string :status
      t.integer :page_count
      t.integer :chunk_count
      t.jsonb :metadata

      t.timestamps
    end
  end
end

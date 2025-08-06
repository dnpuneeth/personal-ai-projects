class AddDeletedDocumentToAiEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :ai_events, :deleted_document, null: true, foreign_key: true
  end
end

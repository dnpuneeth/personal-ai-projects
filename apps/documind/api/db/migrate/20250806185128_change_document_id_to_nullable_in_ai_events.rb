class ChangeDocumentIdToNullableInAiEvents < ActiveRecord::Migration[8.0]
  def up
    change_column_null :ai_events, :document_id, true
  end
  
  def down
    # Note: This rollback will fail if there are any ai_events with null document_id
    # You would need to clean up or reassign those records first
    change_column_null :ai_events, :document_id, false
  end
end
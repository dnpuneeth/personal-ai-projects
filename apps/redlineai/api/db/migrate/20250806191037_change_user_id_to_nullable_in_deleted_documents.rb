class ChangeUserIdToNullableInDeletedDocuments < ActiveRecord::Migration[8.0]
  def up
    change_column_null :deleted_documents, :user_id, true
  end
  
  def down
    # Note: This rollback will fail if there are any deleted_documents with null user_id
    # You would need to clean up or reassign those records first
    change_column_null :deleted_documents, :user_id, false
  end
end
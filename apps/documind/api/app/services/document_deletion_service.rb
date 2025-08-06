class DocumentDeletionService
  def initialize(document)
    @document = document
  end
  
  def call
    return false unless @document
    
    ActiveRecord::Base.transaction do
      # Collect AI usage data before deletion
      ai_events = @document.ai_events.includes(:document)
      total_cost_cents = ai_events.sum(:cost_cents)
      total_tokens_used = ai_events.sum(:tokens_used)
      ai_events_count = ai_events.count
      
      # Create deleted document record to preserve usage data
      deleted_document = create_deleted_document_record(
        total_cost_cents: total_cost_cents,
        total_tokens_used: total_tokens_used,
        ai_events_count: ai_events_count
      )
      
      # Update AI events to reference the deleted document record
      ai_events.update_all(
        document_id: nil,
        deleted_document_id: deleted_document.id
      )
      
      # Clear cached AI analysis results
      clear_document_cache(@document.id)
      
      # Delete the document (this will also delete chunks due to dependent: :destroy)
      @document.destroy!
      
      Rails.logger.info "Document #{@document.id} deleted and usage data preserved in DeletedDocument #{deleted_document.id}"
      
      deleted_document
    end
  rescue => e
    Rails.logger.error "Error deleting document #{@document.id}: #{e.message}"
    raise e
  end
  
  private
  
  def create_deleted_document_record(total_cost_cents:, total_tokens_used:, ai_events_count:)
    deleted_document_attrs = {
      user: @document.user, # This can be nil for anonymous documents
      original_document_id: @document.id,
      title: @document.title,
      file_type: @document.file_type,
      page_count: @document.page_count || 0,
      chunk_count: @document.chunk_count || 0,
      total_cost_cents: total_cost_cents,
      total_tokens_used: total_tokens_used,
      ai_events_count: ai_events_count,
      deleted_at: Time.current
    }
    
    Rails.logger.info "Creating DeletedDocument for #{@document.user ? 'user' : 'anonymous'} document #{@document.id}"
    
    DeletedDocument.create!(deleted_document_attrs)
  end
  
  def clear_document_cache(document_id)
    # Clear all cached AI analysis results for this document
    pattern = "ai_analysis:#{document_id}:*"
    Rails.cache.delete_matched(pattern)
    Rails.logger.info "Cleared cache for document #{document_id}"
  end
end
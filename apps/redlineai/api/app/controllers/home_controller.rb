class HomeController < ApplicationController
  def index
    if user_signed_in?
      # User-specific data for signed-in users
      @total_documents = current_user.documents.count
      @completed_documents = current_user.documents.completed.count
      @recent_documents = current_user.documents.recent.limit(5)
      
      # Get AI events for user's documents
      user_document_ids = current_user.documents.pluck(:id)
      @total_ai_events = AiEvent.where(document_id: user_document_ids).count
    else
      # Global/demo data for anonymous users (no personal documents shown)
      @total_documents = Document.count
      @completed_documents = Document.completed.count
      @recent_documents = [] # Don't show any documents for anonymous users
      @total_ai_events = AiEvent.count
    end
  end
end 
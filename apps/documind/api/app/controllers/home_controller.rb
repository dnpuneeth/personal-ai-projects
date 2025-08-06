class HomeController < ApplicationController
  def index
    @total_documents = Document.count
    @completed_documents = Document.completed.count
    @recent_documents = Document.recent.limit(5)
    @total_ai_events = AiEvent.count
  end
end 
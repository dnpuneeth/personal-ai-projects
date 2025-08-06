class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :destroy]
  before_action :check_document_upload_limit!, only: [:create]

  def index
    if user_signed_in?
      @documents = current_user.documents.recent.page(params[:page]).per(20)
    else
      # Anonymous users can only see their own documents via session
      document_ids = session[:anonymous_document_ids] || []
      @documents = Document.where(id: document_ids).recent.page(params[:page]).per(20)
    end
  end

  def show
    # API response
    respond_to do |format|
      format.html
      format.json do
        render json: {
          id: @document.id,
          title: @document.title,
          status: @document.status,
          page_count: @document.page_count,
          chunk_count: @document.chunk_count,
          created_at: @document.created_at,
          updated_at: @document.updated_at
        }
      end
    end
  end

  def new
    @document = Document.new
  end

  def create
    allowed_types = ['application/pdf', 'text/plain']
    unless allowed_types.include?(params[:file]&.content_type)
      respond_to do |format|
        format.html do
          flash.now[:alert] = 'Only PDF and TXT files are supported'
          render :new, status: :unprocessable_entity
        end
        format.json do
          render json: { error: 'Only PDF and TXT files are supported' }, status: :bad_request
        end
      end
      return
    end

    Rails.logger.info "Creating document: user_signed_in=#{user_signed_in?}, current_user=#{current_user.inspect}, anonymous_user=#{anonymous_user?}"
    
    @document = Document.new(
      title: params[:file].original_filename,
      status: 'pending',
      user: current_user
    )
    @document.file.attach(params[:file])
    
    Rails.logger.info "Document created with user_id=#{@document.user_id}"

    if @document.save
      # Track document upload
      increment_anonymous_document_count!
      
      # Store document ID for anonymous users
      if anonymous_user?
        session[:anonymous_document_ids] ||= []
        session[:anonymous_document_ids] << @document.id
      end
      
      # Enqueue text extraction job
      ExtractTextJob.perform_later(@document.id)
      
      respond_to do |format|
        format.html do
          redirect_to @document, notice: 'Document uploaded successfully! Processing will begin shortly.'
        end
        format.json do
          render json: {
            document_id: @document.id,
            status: @document.status,
            title: @document.title
          }, status: :created
        end
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:alert] = @document.errors.full_messages.join(', ')
          render :new, status: :unprocessable_entity
        end
        format.json do
          render json: { error: @document.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    # Check if this is an anonymous document before deletion
    is_anonymous_document = @document.user.nil?
    
    Rails.logger.info "Deleting document #{@document.id}: is_anonymous=#{is_anonymous_document}, current_user=#{user_signed_in? ? current_user.id : 'none'}"
    Rails.logger.info "Session before deletion: anonymous_documents_count=#{session[:anonymous_documents_count]}, anonymous_id=#{session[:anonymous_id]}"
    
    # Get AI events count before deletion (since deletion service will move them)
    ai_events_count = @document.ai_events.count
    Rails.logger.info "Document has #{ai_events_count} AI events before deletion"
    
    deletion_service = DocumentDeletionService.new(@document)
    deleted_document = deletion_service.call
    
    # Decrement anonymous document count if this document belongs to current anonymous session
    if document_belongs_to_anonymous_session?(@document)
      Rails.logger.info "Document belongs to anonymous session, decrementing count"
      decrement_anonymous_document_count!
      
      # Also decrement AI actions count based on how many AI events were performed
      Rails.logger.info "Refunding #{ai_events_count} AI actions for deleted document"
      
      ai_events_count.times do
        decrement_anonymous_ai_action_count!
      end
      
      # Remove from anonymous document IDs
      session[:anonymous_document_ids].delete(@document.id)
      Rails.logger.info "Removed document #{@document.id} from anonymous session"
      Rails.logger.info "Session after cleanup: anonymous_documents_count=#{session[:anonymous_documents_count]}, anonymous_ai_actions_count=#{session[:anonymous_ai_actions_count]}"
    elsif is_anonymous_document
      Rails.logger.info "Document was anonymous but not in current session"
    else
      Rails.logger.info "Document belongs to authenticated user"
    end
    
    document_type = is_anonymous_document ? 'anonymous' : 'user'
    Rails.logger.info "Successfully deleted #{document_type} document #{@document.id}"
    
    respond_to do |format|
      format.html { 
        redirect_to documents_path, 
        notice: 'Document was successfully deleted. Usage data has been preserved.' 
      }
      format.json { 
        response_data = {
          message: 'Document deleted successfully',
          document_type: document_type,
          deleted_document_id: deleted_document.id,
          preserved_data: {
            total_cost_cents: deleted_document.total_cost_cents,
            total_tokens_used: deleted_document.total_tokens_used,
            ai_events_count: deleted_document.ai_events_count
          }
        }
        
        # Add anonymous session info if applicable
        if is_anonymous_document
          response_data[:anonymous_session] = {
            documents_count: session[:anonymous_documents_count].to_i,
            ai_actions_count: session[:anonymous_ai_actions_count].to_i,
            remaining_uploads: [User::ANONYMOUS_DOCUMENT_LIMIT - session[:anonymous_documents_count].to_i, 0].max
          }
        end
        
        render json: response_data
      }
    end
  rescue => e
    Rails.logger.error "Failed to delete document #{@document.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    respond_to do |format|
      format.html { 
        redirect_to documents_path, 
        alert: "Error deleting document: #{e.message}" 
      }
      format.json { 
        render json: { 
          error: e.message,
          document_id: @document.id,
          document_type: @document.user ? 'user' : 'anonymous'
        }, status: :unprocessable_entity 
      }
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html do
        flash[:alert] = 'Document not found'
        redirect_to documents_path
      end
      format.json do
        render json: { error: 'Document not found' }, status: :not_found
      end
    end
  end

  private

  def clear_document_cache(document_id)
    # Clear all cached AI analysis results for this document
    pattern = "ai_analysis:#{document_id}:*"
    Rails.cache.delete_matched(pattern)
    Rails.logger.info "Cleared cache for document #{document_id}"
  end
end 
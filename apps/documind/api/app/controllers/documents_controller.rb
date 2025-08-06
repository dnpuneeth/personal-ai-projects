class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :destroy]

  def index
    @documents = Document.recent.page(params[:page]).per(20)
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
    unless params[:file]&.content_type == 'application/pdf'
      respond_to do |format|
        format.html do
          flash.now[:alert] = 'Only PDF files are supported'
          render :new, status: :unprocessable_entity
        end
        format.json do
          render json: { error: 'Only PDF files are supported' }, status: :bad_request
        end
      end
      return
    end

    @document = Document.new(
      title: params[:file].original_filename,
      status: 'pending'
    )
    @document.file.attach(params[:file])

    if @document.save
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
    document_id = @document.id
    @document.destroy!
    
    # Clear cached AI analysis results for this document
    clear_document_cache(document_id)
    
    respond_to do |format|
      format.html { 
        redirect_to documents_path, 
        notice: 'Document was successfully deleted.' 
      }
      format.json { head :no_content }
    end
  rescue => e
    respond_to do |format|
      format.html { 
        redirect_to documents_path, 
        alert: "Error deleting document: #{e.message}" 
      }
      format.json { 
        render json: { error: e.message }, status: :unprocessable_entity 
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
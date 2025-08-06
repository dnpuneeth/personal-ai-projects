require "test_helper"

class DocumentProcessingWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    # Clear any existing jobs
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
  end

  test "complete document upload and processing workflow" do
    # Step 1: Upload document
    file = create_test_pdf_file("Sample contract content with terms and conditions.")
    
    assert_difference("Document.count") do
      post documents_path, params: { 
        document: { 
          file: Rack::Test::UploadedFile.new(file.path, "application/pdf", true)
        } 
      }
    end
    
    document = Document.last
    assert_equal "pending", document.status
    assert_redirected_to document_path(document)
    
    # Step 2: Process text extraction
    mock_pdf_extraction(document)
    
    assert_enqueued_with(job: ExtractTextJob, args: [document.id]) do
      # Trigger the job manually for testing
      ExtractTextJob.perform_now(document.id)
    end
    
    document.reload
    assert_equal "processing", document.status
    assert document.doc_chunks.count > 0
    
    # Step 3: Generate embeddings
    mock_embedding_generation
    
    assert_enqueued_with(job: GenerateEmbeddingsJob, args: [document.id]) do
      GenerateEmbeddingsJob.perform_now(document.id)
    end
    
    document.reload
    assert_equal "completed", document.status
    
    # Verify embeddings are generated
    document.doc_chunks.each do |chunk|
      chunk.reload
      assert chunk.embedding.present?
    end
    
    # Step 4: Verify document can be analyzed
    get document_path(document)
    assert_response :success
    assert_select ".ai-analysis-section"
    assert_select "button", text: /Summarize/
  end

  test "document upload with invalid file type" do
    file = create_test_file("test.txt", "text/plain", "This is a text file.")
    
    assert_no_difference("Document.count") do
      post documents_path, params: { 
        document: { 
          file: Rack::Test::UploadedFile.new(file.path, "text/plain", true)
        } 
      }
    end
    
    assert_redirected_to new_document_path
    follow_redirect!
    assert_match(/invalid file type/i, flash[:alert])
  end

  test "document processing failure handling" do
    file = create_test_pdf_file("Test content")
    
    post documents_path, params: { 
      document: { 
        file: Rack::Test::UploadedFile.new(file.path, "application/pdf", true)
      } 
    }
    
    document = Document.last
    
    # Mock PDF extraction failure
    PDF::Reader.any_instance.stubs(:pages).raises(StandardError.new("PDF corruption"))
    
    ExtractTextJob.perform_now(document.id)
    
    document.reload
    assert_equal "failed", document.status
    assert document.metadata["error"].present?
    
    # Verify UI shows error state
    get document_path(document)
    assert_response :success
    assert_select ".status-badge.status-failed"
    assert_select ".error-message"
  end

  test "end-to-end AI analysis workflow" do
    # Setup completed document
    document = create_completed_document_with_embeddings
    
    # Test summarization
    mock_ai_analysis_requests
    
    post summarize_ai_document_path(document)
    assert_response :success
    assert_select ".ai-result"
    assert_select "h3", "Document Summary"
    
    # Verify AI event was created
    ai_event = document.ai_events.last
    assert_equal "summarize_and_risks", ai_event.event_type
    assert ai_event.tokens_used > 0
    
    # Test question answering
    post answer_ai_document_path(document), params: { 
      question: "What are the key terms?" 
    }
    assert_response :success
    assert_select ".ai-result"
    assert_select "h3", "Answer"
    
    # Test redlines
    post redlines_ai_document_path(document)
    assert_response :success
    assert_select ".ai-result"
    assert_select "h3", "Proposed Redlines"
  end

  test "caching workflow reduces API calls" do
    document = create_completed_document_with_embeddings
    mock_ai_analysis_requests
    
    # First request should hit the API
    post summarize_ai_document_path(document), as: :json
    assert_response :success
    
    first_response = JSON.parse(response.body)
    assert_not first_response["cached"]
    
    # Reset request stubs to ensure no more API calls
    WebMock.reset!
    
    # Second request should hit cache
    post summarize_ai_document_path(document), as: :json
    assert_response :success
    
    second_response = JSON.parse(response.body)
    assert second_response["cached"]
    
    # Results should be the same
    assert_equal first_response["summary"], second_response["summary"]
  end

  test "document deletion clears associated data and cache" do
    document = create_completed_document_with_embeddings
    document_id = document.id
    
    # Set up some cached data
    Rails.cache.write("ai_analysis:#{document_id}:test", { result: "cached" })
    assert Rails.cache.exist?("ai_analysis:#{document_id}:test")
    
    # Create AI events
    document.ai_events.create!(
      event_type: "summarize_and_risks",
      model: "gpt-4o-mini",
      tokens_used: 100,
      cost_cents: 10
    )
    
    chunk_ids = document.doc_chunks.pluck(:id)
    event_ids = document.ai_events.pluck(:id)
    
    # Delete document
    delete document_path(document)
    assert_response :redirect
    assert_redirected_to documents_path
    
    # Verify cleanup
    assert_not Document.exists?(document_id)
    
    chunk_ids.each do |chunk_id|
      assert_not DocChunk.exists?(chunk_id)
    end
    
    event_ids.each do |event_id|
      assert_not AiEvent.exists?(event_id)
    end
    
    # Verify cache is cleared
    assert_not Rails.cache.exist?("ai_analysis:#{document_id}:test")
  end

  test "cost tracking throughout workflow" do
    document = create_completed_document_with_embeddings
    
    initial_cost = AiEvent.sum(:cost_cents)
    
    # Perform AI analysis
    mock_ai_analysis_requests
    
    post summarize_ai_document_path(document), as: :json
    post answer_ai_document_path(document), 
         params: { question: "Test question?" }, 
         as: :json
    post redlines_ai_document_path(document), as: :json
    
    final_cost = AiEvent.sum(:cost_cents)
    
    # Cost should have increased
    assert final_cost > initial_cost
    
    # Check costs page
    get "/costs"
    assert_response :success
    assert_select ".total-cost"
    assert_select ".cost-breakdown"
  end

  test "error handling in AI analysis workflow" do
    document = create_completed_document_with_embeddings
    
    # Mock API error
    stub_request(:post, /api\.openai\.com/)
      .to_return(status: 500, body: "API Error")
    
    post summarize_ai_document_path(document)
    assert_response :redirect
    follow_redirect!
    assert_match(/error/i, flash[:alert])
    
    # Error should not create AI event
    assert_equal 0, document.ai_events.count
  end

  test "concurrent document processing" do
    files = 3.times.map { |i| 
      create_test_pdf_file("Document #{i} content") 
    }
    
    documents = []
    
    # Upload multiple documents
    files.each do |file|
      post documents_path, params: { 
        document: { 
          file: Rack::Test::UploadedFile.new(file.path, "application/pdf", true)
        } 
      }
      documents << Document.last
    end
    
    # Mock processing for all documents
    mock_pdf_extraction_for_multiple_documents(documents)
    mock_embedding_generation
    
    # Process all documents
    documents.each do |document|
      ExtractTextJob.perform_now(document.id)
      GenerateEmbeddingsJob.perform_now(document.id)
    end
    
    # Verify all documents are completed
    documents.each do |document|
      document.reload
      assert_equal "completed", document.status
      assert document.doc_chunks.count > 0
    end
  end

  private

  def create_completed_document_with_embeddings
    document = create_document_with_chunks("Test Document", 2)
    document.update!(status: :completed)
    
    # Add embeddings to chunks
    document.doc_chunks.each do |chunk|
      chunk.update!(embedding: Array.new(1536, 0.1))
    end
    
    document
  end

  def mock_pdf_extraction(document)
    PDF::Reader.any_instance.stubs(:pages).returns([
      mock_page_with_text("Sample contract content"),
      mock_page_with_text("Terms and conditions section")
    ])
    
    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("pdf content")
    mock_attachment.stubs(:byte_size).returns(2048)
    document.stubs(:file).returns(mock_attachment)
    document.file.stubs(:attached?).returns(true)
  end

  def mock_pdf_extraction_for_multiple_documents(documents)
    documents.each_with_index do |document, index|
      PDF::Reader.any_instance.stubs(:pages).returns([
        mock_page_with_text("Document #{index} content section 1"),
        mock_page_with_text("Document #{index} content section 2")
      ])
      
      mock_attachment = mock('attachment')
      mock_attachment.stubs(:download).returns("pdf content #{index}")
      mock_attachment.stubs(:byte_size).returns(1024 + index * 100)
      document.stubs(:file).returns(mock_attachment)
      document.file.stubs(:attached?).returns(true)
    end
  end

  def mock_embedding_generation
    mock_embedding_response = {
      object: "list",
      data: [
        {
          object: "embedding",
          embedding: Array.new(1536, 0.1),
          index: 0
        }
      ],
      model: "text-embedding-3-small",
      usage: {
        prompt_tokens: 10,
        total_tokens: 10
      }
    }
    
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: mock_embedding_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def mock_ai_analysis_requests
    # Mock embedding request for search
    mock_embedding_generation
    
    # Mock chat completion request
    mock_chat_response = {
      id: "chatcmpl-test",
      object: "chat.completion",
      created: Time.current.to_i,
      model: "gpt-4o-mini",
      choices: [
        {
          index: 0,
          message: {
            role: "assistant",
            content: JSON.generate({
              summary: "Test document summary",
              key_risks: ["Risk 1", "Risk 2"],
              confidence: 0.9,
              answer: "This is the answer",
              citations: ["Chunk 1"],
              redlines: ["Suggested change 1"]
            })
          },
          finish_reason: "stop"
        }
      ],
      usage: {
        prompt_tokens: 100,
        completion_tokens: 50,
        total_tokens: 150
      }
    }
    
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        body: mock_chat_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def mock_page_with_text(text)
    page = mock('page')
    page.stubs(:text).returns(text)
    page
  end

  def create_test_file(filename, content_type, content)
    file = Tempfile.new([filename.split('.').first, ".#{filename.split('.').last}"])
    file.write(content)
    file.rewind
    file
  end
end
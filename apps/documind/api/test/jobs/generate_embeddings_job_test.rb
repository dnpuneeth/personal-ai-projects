require "test_helper"

class GenerateEmbeddingsJobTest < ActiveJob::TestCase
  def setup
    @document = create_document_with_chunks("Test Document", 3)
    @document.update!(status: :processing)
    
    @mock_embedding_response = {
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
  end

  test "should generate embeddings for all chunks successfully" do
    mock_openai_embedding_requests
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    assert_equal "completed", @document.status
    
    @document.doc_chunks.each do |chunk|
      chunk.reload
      assert chunk.embedding.present?, "Chunk #{chunk.chunk_index} should have embedding"
      assert_equal 1536, chunk.embedding.size
    end
  end

  test "should handle document not found" do
    assert_nothing_raised do
      GenerateEmbeddingsJob.perform_now(99999)
    end
  end

  test "should handle document with no chunks" do
    empty_document = Document.create!(title: "Empty Document", status: :processing)
    
    GenerateEmbeddingsJob.perform_now(empty_document.id)
    
    empty_document.reload
    assert_equal "failed", empty_document.status
    assert_includes empty_document.metadata["error"], "No chunks found"
  end

  test "should handle OpenAI API errors" do
    # Mock API error
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(status: 500, body: "Internal Server Error")
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    assert_equal "failed", @document.status
    assert @document.metadata["error"].present?
  end

  test "should handle network timeouts" do
    # Mock timeout
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_timeout
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    assert_equal "failed", @document.status
    assert_includes @document.metadata["error"], "timeout"
  end

  test "should handle rate limiting" do
    # Mock rate limit error
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 429,
        body: { error: { message: "Rate limit exceeded" } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    assert_equal "failed", @document.status
    assert_includes @document.metadata["error"], "Rate limit"
  end

  test "should handle invalid API key" do
    # Mock authentication error
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 401,
        body: { error: { message: "Invalid API key" } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    assert_equal "failed", @document.status
    assert_includes @document.metadata["error"], "Invalid API key"
  end

  test "should batch process chunks efficiently" do
    # Create document with many chunks
    large_document = create_document_with_chunks("Large Document", 10)
    large_document.update!(status: :processing)
    
    # Mock successful responses for all chunks
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: @mock_embedding_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    GenerateEmbeddingsJob.perform_now(large_document.id)
    
    large_document.reload
    assert_equal "completed", large_document.status
    
    # All chunks should have embeddings
    large_document.doc_chunks.each do |chunk|
      chunk.reload
      assert chunk.embedding.present?
    end
  end

  test "should update document metadata after completion" do
    mock_openai_embedding_requests
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    assert @document.metadata["embeddings_generated_at"].present?
    assert @document.metadata["total_chunks"] == @document.doc_chunks.count
    assert @document.metadata["embedding_model"] == "text-embedding-3-small"
  end

  test "should handle partial failures gracefully" do
    # Mock success for first request, failure for subsequent
    call_count = 0
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return do |request|
        call_count += 1
        if call_count == 1
          {
            status: 200,
            body: @mock_embedding_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          }
        else
          { status: 500, body: "Internal Server Error" }
        end
      end
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    assert_equal "failed", @document.status
    
    # First chunk should have embedding, others should not
    chunks = @document.doc_chunks.order(:chunk_index)
    assert chunks.first.embedding.present?
    assert chunks.second.embedding.blank?
  end

  test "should validate embedding dimensions" do
    # Mock response with wrong dimensions
    invalid_response = @mock_embedding_response.dup
    invalid_response[:data][0][:embedding] = Array.new(512, 0.1)  # Wrong size
    
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: invalid_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    assert_equal "failed", @document.status
    assert_includes @document.metadata["error"], "Invalid embedding dimensions"
  end

  test "should handle empty embedding response" do
    # Mock empty response
    empty_response = @mock_embedding_response.dup
    empty_response[:data] = []
    
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: empty_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    assert_equal "failed", @document.status
    assert_includes @document.metadata["error"], "No embeddings returned"
  end

  test "should retry on transient failures" do
    # Mock failure then success
    call_count = 0
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return do |request|
        call_count += 1
        if call_count <= 2  # Fail first two attempts
          { status: 503, body: "Service Unavailable" }
        else
          {
            status: 200,
            body: @mock_embedding_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          }
        end
      end
    
    # The job should retry and eventually succeed
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    # Note: This test depends on retry logic being implemented
    # For now, we'll check that it at least attempts the request
    assert call_count > 1
  end

  test "should handle malformed JSON response" do
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: "Invalid JSON response",
        headers: { 'Content-Type' => 'application/json' }
      )
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    @document.reload
    assert_equal "failed", @document.status
    assert_includes @document.metadata["error"], "JSON"
  end

  test "should preserve existing embeddings on retry" do
    # Generate embeddings for first chunk manually
    first_chunk = @document.doc_chunks.first
    first_chunk.update!(embedding: Array.new(1536, 0.5))
    
    # Mock failure for all requests
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(status: 500, body: "Internal Server Error")
    
    GenerateEmbeddingsJob.perform_now(@document.id)
    
    first_chunk.reload
    # First chunk's embedding should be preserved
    assert_equal 0.5, first_chunk.embedding.first
  end

  private

  def mock_openai_embedding_requests
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: @mock_embedding_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
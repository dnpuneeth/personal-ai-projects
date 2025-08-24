require "test_helper"

class AiControllerTest < ActionDispatch::IntegrationTest
  def setup
    @document = documents(:sample_document)
    @processing_document = documents(:processing_document)
    
    # Mock successful OpenAI responses
    @mock_chat_response = {
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
              confidence: 0.9
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

  # Summarize tests
  test "should summarize and risks for completed document" do
    mock_ai_requests
    
    post summarize_ai_document_path(@document)
    assert_response :success
    assert_select ".ai-result"
    assert_select "h3", "Document Summary"
  end

  test "should summarize and risks as json" do
    mock_ai_requests
    
    post summarize_ai_document_path(@document), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?("summary")
    assert json_response.key?("key_risks")
    assert json_response.key?("confidence")
  end

  test "should not summarize processing document" do
    post summarize_ai_document_path(@processing_document)
    assert_response :redirect
    follow_redirect!
    assert_match(/not completed/i, flash[:alert])
  end

  test "should create ai_event for summarize" do
    mock_ai_requests
    
    assert_difference("AiEvent.count") do
      post summarize_ai_document_path(@document), as: :json
    end
    
    event = AiEvent.last
    assert_equal "summarize_and_risks", event.event_type
    assert_equal @document, event.document
    assert event.tokens_used > 0
  end

  # Answer question tests
  test "should answer question for completed document" do
    mock_ai_requests
    
    post answer_ai_document_path(@document), 
         params: { question: "What are the payment terms?" }
    assert_response :success
    assert_select ".ai-result"
    assert_select "h3", "Answer"
  end

  test "should answer question as json" do
    mock_ai_requests
    
    post answer_ai_document_path(@document), 
         params: { question: "What are the payment terms?" }, 
         as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?("answer")
    assert json_response.key?("confidence")
    assert json_response.key?("citations")
  end

  test "should require question parameter" do
    post answer_ai_document_path(@document), params: { question: "" }
    assert_response :redirect
    follow_redirect!
    assert_match(/question.*required/i, flash[:alert])
  end

  test "should require question parameter as json" do
    post answer_ai_document_path(@document), 
         params: { question: "" }, 
         as: :json
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert_match(/question.*required/i, json_response["error"])
  end

  test "should create ai_event for answer_question" do
    mock_ai_requests
    
    assert_difference("AiEvent.count") do
      post answer_ai_document_path(@document), 
           params: { question: "Test question?" }, 
           as: :json
    end
    
    event = AiEvent.last
    assert_equal "answer_question", event.event_type
    assert_equal @document, event.document
    assert_includes event.metadata["question"], "Test question?"
  end

  # Propose redlines tests
  test "should propose redlines for completed document" do
    mock_ai_requests
    
    post redlines_ai_document_path(@document)
    assert_response :success
    assert_select ".ai-result"
    assert_select "h3", "Proposed Redlines"
  end

  test "should propose redlines as json" do
    mock_ai_requests
    
    post redlines_ai_document_path(@document), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response.key?("redlines")
    assert json_response.key?("confidence")
  end

  test "should create ai_event for propose_redlines" do
    mock_ai_requests
    
    assert_difference("AiEvent.count") do
      post redlines_ai_document_path(@document), as: :json
    end
    
    event = AiEvent.last
    assert_equal "propose_redlines", event.event_type
    assert_equal @document, event.document
  end

  # Caching tests
  test "should cache ai results" do
    mock_ai_requests
    
    # First request should hit the API
    post summarize_ai_document_path(@document), as: :json
    assert_response :success
    
    first_response = JSON.parse(response.body)
    assert_not first_response["cached"]
    
    # Second request should hit cache
    post summarize_ai_document_path(@document), as: :json
    assert_response :success
    
    second_response = JSON.parse(response.body)
    assert second_response["cached"]
  end

  test "should use different cache keys for different questions" do
    mock_ai_requests
    
    # First question
    post answer_ai_document_path(@document), 
         params: { question: "Question 1?" }, 
         as: :json
    first_response = JSON.parse(response.body)
    
    # Second question should not hit cache
    post answer_ai_document_path(@document), 
         params: { question: "Question 2?" }, 
         as: :json
    second_response = JSON.parse(response.body)
    
    assert_not second_response["cached"]
  end

  # Error handling tests
  test "should handle document not found" do
    post summarize_ai_document_path(id: 99999)
    assert_response :redirect
    follow_redirect!
    assert_match(/not found/i, flash[:alert])
  end

  test "should handle document not found as json" do
    post summarize_ai_document_path(id: 99999), as: :json
    assert_response :not_found
    
    json_response = JSON.parse(response.body)
    assert_equal "Document not found", json_response["error"]
  end

  test "should handle openai api errors" do
    # Mock API error
    stub_request(:post, /api\.openai\.com/)
      .to_return(status: 500, body: "Internal Server Error")
    
    post summarize_ai_document_path(@document), as: :json
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert json_response["error"].present?
  end

  test "should handle network timeouts" do
    # Mock timeout
    stub_request(:post, /api\.openai\.com/)
      .to_timeout
    
    post summarize_ai_document_path(@document), as: :json
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert_match(/timeout|network/i, json_response["error"])
  end

  test "should handle invalid json responses" do
    # Mock invalid JSON response
    stub_request(:post, /api\.openai\.com/)
      .to_return(
        status: 200,
        body: "Invalid JSON response",
        headers: { 'Content-Type' => 'application/json' }
      )
    
    post summarize_ai_document_path(@document), as: :json
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert_match(/parse|json/i, json_response["error"])
  end

  # Security tests
  test "should sanitize question input" do
    mock_ai_requests
    
    malicious_question = "<script>alert('xss')</script>What are the terms?"
    
    post answer_ai_document_path(@document), 
         params: { question: malicious_question }
    assert_response :success
    
    # Response should not contain the script tag
    assert_not_includes response.body, "<script>"
  end

  test "should limit question length" do
    long_question = "a" * 10001  # Assuming max length is 10000
    
    post answer_ai_document_path(@document), 
         params: { question: long_question }, 
         as: :json
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert_match(/too long|length/i, json_response["error"])
  end

  private

  def mock_ai_requests
    # Mock embedding request
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: @mock_embedding_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    # Mock chat completion request
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        body: @mock_chat_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
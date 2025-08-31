require "test_helper"

class ChatControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @document = documents(:one)

    # Ensure document is completed
    @document.update!(status: 'completed')

    # Create some doc chunks for the document
    @document.doc_chunks.create!(
      content: "This is a test document chunk with some content for testing.",
      chunk_index: 0,
      start_token: 0,
      end_token: 50
    )
  end

  test "should show chat interface" do
    sign_in @user
    get chat_document_path(@document)
    assert_response :success
    assert_select "h2", "Chat with AI"
  end

  test "should create conversation for new user" do
    sign_in @user

    assert_difference "Conversation.count" do
      get chat_document_path(@document)
    end

    conversation = @document.conversations.find_by(user: @user)
    assert conversation.present?
    assert conversation.active?
  end

  test "should reuse existing active conversation" do
    sign_in @user

    # Create a conversation first
    conversation = @document.conversations.create!(
      user: @user,
      title: "Test conversation",
      expires_at: 1.day.from_now
    )

    assert_no_difference "Conversation.count" do
      get chat_document_path(@document)
    end

    assert_equal conversation, assigns(:conversation)
  end

  test "should send message successfully" do
    sign_in @user
    conversation = @document.get_or_create_conversation(@user)

    assert_difference "Message.count", 2 do # User message + AI response
      post send_chat_message_document_path(@document),
           params: { content: "What is this document about?" },
           as: :json
    end

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert json_response["user_message"]
    assert json_response["ai_message"]
  end

  test "should require message content" do
    sign_in @user
    post send_chat_message_document_path(@document),
         params: { content: "" },
         as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_match /content.*required/i, json_response["error"]
  end

  test "should respect conversation limits" do
    sign_in @user
    conversation = @document.get_or_create_conversation(@user)

    # Set message count to limit
    conversation.update!(message_count: 20) # Free user limit

    post send_chat_message_document_path(@document),
         params: { content: "This should fail" },
         as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_match /limit.*reached/i, json_response["error"]
  end

  test "should create new conversation" do
    sign_in @user
    conversation = @document.get_or_create_conversation(@user)

    post new_conversation_document_path(@document)
    assert_response :redirect

    # Should redirect to chat page
    follow_redirect!
    assert_response :success
  end

  test "should handle anonymous users" do
    # Test without signing in
    get chat_document_path(@document)
    assert_response :success

    # Should create anonymous conversation
    conversation = @document.conversations.find_by(user: nil)
    assert conversation.present?
    assert conversation.active?
  end

  test "should show conversation stats" do
    sign_in @user
    conversation = @document.get_or_create_conversation(@user)

    get chat_document_path(@document)
    assert_response :success

    # Should show message count and expiry
    assert_select "span", /#{conversation.message_count} messages/
    assert_select "span", /Expires: #{conversation.expires_at.strftime("%b %d")}/
  end
end

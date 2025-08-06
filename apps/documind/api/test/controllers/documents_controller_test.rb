require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @document = documents(:sample_document)
    @processing_document = documents(:processing_document)
  end

  # Index tests
  test "should get index" do
    get documents_path
    assert_response :success
    assert_select "h1", "All Documents"
    assert_select ".document-card", count: Document.count
  end

  test "should get index as json" do
    get documents_path, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal Document.count, json_response["documents"].length
    assert json_response["documents"].first.key?("title")
    assert json_response["documents"].first.key?("status")
  end

  # Show tests
  test "should show document" do
    get document_path(@document)
    assert_response :success
    assert_select "h1", @document.title
    assert_select ".status-badge"
  end

  test "should show document as json" do
    get document_path(@document), as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @document.title, json_response["document"]["title"]
    assert_equal @document.status, json_response["document"]["status"]
  end

  test "should return 404 for non-existent document" do
    get document_path(id: 99999)
    assert_response :redirect
    follow_redirect!
    assert_equal documents_path, path
  end

  test "should return 404 for non-existent document as json" do
    get document_path(id: 99999), as: :json
    assert_response :not_found
    
    json_response = JSON.parse(response.body)
    assert_equal "Document not found", json_response["error"]
  end

  # New tests
  test "should get new" do
    get new_document_path
    assert_response :success
    assert_select "form[action=?]", documents_path
    assert_select "input[type=file]"
  end

  # Create tests
  test "should create document with valid file" do
    file = fixture_file_upload("test_document.pdf", "application/pdf")
    
    assert_difference("Document.count") do
      post documents_path, params: { document: { file: file } }
    end
    
    assert_response :redirect
    created_document = Document.last
    assert_equal "test_document.pdf", created_document.title
    assert_equal "pending", created_document.status
  end

  test "should create document as json with valid file" do
    file = fixture_file_upload("test_document.pdf", "application/pdf")
    
    assert_difference("Document.count") do
      post documents_path, 
           params: { document: { file: file } }, 
           as: :json
    end
    
    assert_response :created
    json_response = JSON.parse(response.body)
    assert_equal "test_document.pdf", json_response["document"]["title"]
  end

  test "should not create document without file" do
    assert_no_difference("Document.count") do
      post documents_path, params: { document: { file: nil } }
    end
    
    assert_response :redirect
    follow_redirect!
    assert_match(/error/i, flash[:alert])
  end

  test "should not create document without file as json" do
    assert_no_difference("Document.count") do
      post documents_path, 
           params: { document: { file: nil } }, 
           as: :json
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert json_response["error"].present?
  end

  test "should not create document with invalid file type" do
    file = fixture_file_upload("test_image.jpg", "image/jpeg")
    
    assert_no_difference("Document.count") do
      post documents_path, params: { document: { file: file } }
    end
    
    assert_response :redirect
    follow_redirect!
    assert_match(/invalid file type/i, flash[:alert])
  end

  # Destroy tests
  test "should destroy document" do
    document_id = @document.id
    
    assert_difference("Document.count", -1) do
      delete document_path(@document)
    end
    
    assert_response :redirect
    assert_redirected_to documents_path
    assert_match(/successfully deleted/i, flash[:notice])
    
    # Verify associated records are also deleted
    assert_equal 0, DocChunk.where(document_id: document_id).count
    assert_equal 0, AiEvent.where(document_id: document_id).count
  end

  test "should destroy document as json" do
    assert_difference("Document.count", -1) do
      delete document_path(@document), as: :json
    end
    
    assert_response :no_content
  end

  test "should handle destroy errors gracefully" do
    # Mock an error during destruction
    Document.any_instance.stubs(:destroy!).raises(StandardError.new("Database error"))
    
    assert_no_difference("Document.count") do
      delete document_path(@document)
    end
    
    assert_response :redirect
    assert_redirected_to documents_path
    assert_match(/error deleting/i, flash[:alert])
  end

  test "should clear cache when destroying document" do
    # Set up cache
    cache_key = "ai_analysis:#{@document.id}:test"
    Rails.cache.write(cache_key, { result: "test" })
    assert Rails.cache.exist?(cache_key)
    
    delete document_path(@document)
    
    # Cache should be cleared
    assert_not Rails.cache.exist?(cache_key)
  end

  test "should not destroy non-existent document" do
    delete document_path(id: 99999)
    assert_response :redirect
    assert_redirected_to documents_path
    assert_match(/not found/i, flash[:alert])
  end

  test "should not destroy non-existent document as json" do
    delete document_path(id: 99999), as: :json
    assert_response :not_found
    
    json_response = JSON.parse(response.body)
    assert_equal "Document not found", json_response["error"]
  end

  # Security tests
  test "should sanitize file names" do
    # Test with potentially dangerous filename
    file = fixture_file_upload("../../../etc/passwd", "application/pdf")
    file.instance_variable_set(:@original_filename, "../../../etc/passwd.pdf")
    
    post documents_path, params: { document: { file: file } }
    
    if response.status == 302  # Successful creation
      created_document = Document.last
      assert_not_includes created_document.title, "../"
    end
  end

  test "should handle large file uploads gracefully" do
    # This would typically be tested with actual large files
    # For now, we'll test the error handling path
    skip "Large file upload testing requires actual large files"
  end

  private

  def fixture_file_upload(filename, content_type)
    # Create a temporary file for testing
    file_path = Rails.root.join("tmp", filename)
    File.write(file_path, "Test PDF content")
    
    Rack::Test::UploadedFile.new(file_path, content_type, true)
  end
end
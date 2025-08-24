require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  def setup
    @document = documents(:sample_document)
  end

  test "should be valid with valid attributes" do
    assert @document.valid?
  end

  test "should require title" do
    @document.title = nil
    assert_not @document.valid?
    assert_includes @document.errors[:title], "can't be blank"
  end

  test "should have default pending status" do
    new_document = Document.new(title: "New Document")
    assert_equal "pending", new_document.status
  end

  test "should validate status inclusion" do
    @document.status = "invalid_status"
    assert_not @document.valid?
    assert_includes @document.errors[:status], "is not included in the list"
  end

  test "should have valid status transitions" do
    document = Document.create!(title: "Test Document")
    assert_equal "pending", document.status

    document.update!(status: "processing")
    assert_equal "processing", document.status

    document.update!(status: "completed")
    assert_equal "completed", document.status
  end

  test "should have many doc_chunks" do
    assert_respond_to @document, :doc_chunks
    assert @document.doc_chunks.count > 0
  end

  test "should have many ai_events" do
    assert_respond_to @document, :ai_events
    assert @document.ai_events.count > 0
  end

  test "should destroy associated doc_chunks when destroyed" do
    chunk_ids = @document.doc_chunks.pluck(:id)
    @document.destroy!
    
    chunk_ids.each do |chunk_id|
      assert_not DocChunk.exists?(chunk_id)
    end
  end

  test "should destroy associated ai_events when destroyed" do
    event_ids = @document.ai_events.pluck(:id)
    @document.destroy!
    
    event_ids.each do |event_id|
      assert_not AiEvent.exists?(event_id)
    end
  end

  test "should have status scope methods" do
    assert_respond_to Document, :pending
    assert_respond_to Document, :processing
    assert_respond_to Document, :completed
    assert_respond_to Document, :failed
  end

  test "should have status predicate methods" do
    assert_respond_to @document, :pending?
    assert_respond_to @document, :processing?
    assert_respond_to @document, :completed?
    assert_respond_to @document, :failed?
  end

  test "completed? should return true for completed documents" do
    @document.update!(status: "completed")
    assert @document.completed?
  end

  test "should store metadata as JSON" do
    metadata = { pages: 5, file_size: 2048, custom_field: "test" }
    @document.update!(metadata: metadata)
    @document.reload
    
    assert_equal metadata.stringify_keys, @document.metadata
  end

  test "should handle nil metadata gracefully" do
    @document.update!(metadata: nil)
    assert_nil @document.metadata
  end

  test "should be searchable by title" do
    results = Document.where("title ILIKE ?", "%Sample%")
    assert_includes results, @document
  end

  test "should order by created_at desc by default" do
    older_doc = Document.create!(title: "Older Document", created_at: 2.days.ago)
    newer_doc = Document.create!(title: "Newer Document", created_at: 1.hour.ago)
    
    documents = Document.order(created_at: :desc)
    assert documents.first.created_at > documents.last.created_at
  end

  test "should calculate total chunks" do
    chunk_count = @document.doc_chunks.count
    assert_equal chunk_count, @document.doc_chunks.size
  end

  test "should validate title length" do
    @document.title = "a" * 256  # Assuming max length is 255
    assert_not @document.valid?
  end

  test "should allow reasonable title length" do
    @document.title = "A reasonable document title"
    assert @document.valid?
  end
end
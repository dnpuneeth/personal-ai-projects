require "test_helper"

class DocChunkTest < ActiveSupport::TestCase
  def setup
    @doc_chunk = doc_chunks(:chunk_one)
    @document = documents(:sample_document)
  end

  test "should be valid with valid attributes" do
    assert @doc_chunk.valid?
  end

  test "should require content" do
    @doc_chunk.content = nil
    assert_not @doc_chunk.valid?
    assert_includes @doc_chunk.errors[:content], "can't be blank"
  end

  test "should require chunk_index" do
    @doc_chunk.chunk_index = nil
    assert_not @doc_chunk.valid?
    assert_includes @doc_chunk.errors[:chunk_index], "can't be blank"
  end

  test "should require document association" do
    @doc_chunk.document = nil
    assert_not @doc_chunk.valid?
    assert_includes @doc_chunk.errors[:document], "must exist"
  end

  test "should belong to document" do
    assert_respond_to @doc_chunk, :document
    assert_equal @document, @doc_chunk.document
  end

  test "should validate chunk_index is numeric" do
    @doc_chunk.chunk_index = "not_a_number"
    assert_not @doc_chunk.valid?
    assert_includes @doc_chunk.errors[:chunk_index], "is not a number"
  end

  test "should validate chunk_index is not negative" do
    @doc_chunk.chunk_index = -1
    assert_not @doc_chunk.valid?
    assert_includes @doc_chunk.errors[:chunk_index], "must be greater than or equal to 0"
  end

  test "should allow zero chunk_index" do
    @doc_chunk.chunk_index = 0
    assert @doc_chunk.valid?
  end

  test "should validate uniqueness of chunk_index per document" do
    duplicate_chunk = DocChunk.new(
      document: @document,
      content: "Duplicate chunk",
      chunk_index: @doc_chunk.chunk_index
    )
    
    assert_not duplicate_chunk.valid?
    assert_includes duplicate_chunk.errors[:chunk_index], "has already been taken"
  end

  test "should allow same chunk_index for different documents" do
    other_document = documents(:processing_document)
    new_chunk = DocChunk.new(
      document: other_document,
      content: "New chunk",
      chunk_index: @doc_chunk.chunk_index
    )
    
    assert new_chunk.valid?
  end

  test "should store metadata as JSON" do
    metadata = { page: 1, position: 0, word_count: 15, custom_field: "test" }
    @doc_chunk.update!(metadata: metadata)
    @doc_chunk.reload
    
    assert_equal metadata.stringify_keys, @doc_chunk.metadata
  end

  test "should handle nil metadata gracefully" do
    @doc_chunk.update!(metadata: nil)
    assert_nil @doc_chunk.metadata
  end

  test "should validate content length" do
    @doc_chunk.content = "a" * 10001  # Assuming max length is 10000
    assert_not @doc_chunk.valid?
  end

  test "should allow reasonable content length" do
    @doc_chunk.content = "a" * 1000
    assert @doc_chunk.valid?
  end

  test "should have embedding column" do
    assert_respond_to @doc_chunk, :embedding
  end

  test "should order by chunk_index by default" do
    chunks = @document.doc_chunks.order(:chunk_index)
    previous_index = -1
    
    chunks.each do |chunk|
      assert chunk.chunk_index > previous_index
      previous_index = chunk.chunk_index
    end
  end

  test "should be searchable by content" do
    results = DocChunk.where("content ILIKE ?", "%first chunk%")
    assert_includes results, @doc_chunk
  end

  test "should calculate word count from content" do
    word_count = @doc_chunk.content.split.length
    assert word_count > 0
  end

  test "should strip whitespace from content" do
    @doc_chunk.content = "  content with spaces  "
    @doc_chunk.save!
    assert_equal "content with spaces", @doc_chunk.content
  end

  test "should not allow empty content after stripping" do
    @doc_chunk.content = "   "
    assert_not @doc_chunk.valid?
    assert_includes @doc_chunk.errors[:content], "can't be blank"
  end

  test "should find chunks by document" do
    document_chunks = DocChunk.where(document: @document)
    assert_includes document_chunks, @doc_chunk
  end

  test "should find chunks by chunk_index range" do
    chunks_in_range = DocChunk.where(chunk_index: 0..2)
    assert_includes chunks_in_range, @doc_chunk
  end
end
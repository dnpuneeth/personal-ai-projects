require "test_helper"

class ExtractTextJobTest < ActiveJob::TestCase
  def setup
    @document = documents(:sample_document)
    @document.update!(status: :pending)
  end

  test "should extract text from PDF successfully" do
    # Mock PDF reader
    mock_pdf_content = "This is extracted text from the PDF document. It contains multiple sentences and paragraphs."
    
    PDF::Reader.any_instance.stubs(:pages).returns([
      mock_page_with_text("This is extracted text from the PDF document."),
      mock_page_with_text("It contains multiple sentences and paragraphs.")
    ])

    # Mock ActiveStorage attachment
    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("mocked pdf content")
    @document.stubs(:file).returns(mock_attachment)
    @document.file.stubs(:attached?).returns(true)

    assert_difference("DocChunk.count", 1) do
      ExtractTextJob.perform_now(@document.id)
    end

    @document.reload
    assert_equal "processing", @document.status
    
    chunk = @document.doc_chunks.first
    assert_includes chunk.content, "extracted text"
    assert_equal 0, chunk.chunk_index
  end

  test "should handle PDF with no text" do
    # Mock empty PDF
    PDF::Reader.any_instance.stubs(:pages).returns([])

    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("empty pdf content")
    @document.stubs(:file).returns(mock_attachment)
    @document.file.stubs(:attached?).returns(true)

    ExtractTextJob.perform_now(@document.id)

    @document.reload
    assert_equal "failed", @document.status
    assert_includes @document.metadata["error"], "No text content"
  end

  test "should handle PDF reading errors" do
    # Mock PDF reader error
    PDF::Reader.any_instance.stubs(:pages).raises(PDF::Reader::MalformedPDFError.new("Invalid PDF"))

    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("corrupted pdf content")
    @document.stubs(:file).returns(mock_attachment)
    @document.file.stubs(:attached?).returns(true)

    ExtractTextJob.perform_now(@document.id)

    @document.reload
    assert_equal "failed", @document.status
    assert_includes @document.metadata["error"], "Invalid PDF"
  end

  test "should handle missing file attachment" do
    @document.stubs(:file).returns(mock('attachment'))
    @document.file.stubs(:attached?).returns(false)

    ExtractTextJob.perform_now(@document.id)

    @document.reload
    assert_equal "failed", @document.status
    assert_includes @document.metadata["error"], "No file attached"
  end

  test "should handle document not found" do
    assert_nothing_raised do
      ExtractTextJob.perform_now(99999)
    end
  end

  test "should chunk large text content" do
    # Create a large text that should be split into multiple chunks
    large_text = "This is a sentence. " * 300  # ~6000 characters
    
    PDF::Reader.any_instance.stubs(:pages).returns([
      mock_page_with_text(large_text)
    ])

    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("large pdf content")
    @document.stubs(:file).returns(mock_attachment)
    @document.file.stubs(:attached?).returns(true)

    assert_difference("DocChunk.count") { |count| count > 1 } do
      ExtractTextJob.perform_now(@document.id)
    end

    chunks = @document.doc_chunks.order(:chunk_index)
    assert chunks.count > 1
    
    # Verify chunk indices are sequential
    chunks.each_with_index do |chunk, index|
      assert_equal index, chunk.chunk_index
    end
  end

  test "should update document metadata after extraction" do
    mock_text = "Sample extracted text content."
    
    PDF::Reader.any_instance.stubs(:pages).returns([
      mock_page_with_text(mock_text)
    ])

    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("pdf content")
    mock_attachment.stubs(:byte_size).returns(2048)
    @document.stubs(:file).returns(mock_attachment)
    @document.file.stubs(:attached?).returns(true)

    ExtractTextJob.perform_now(@document.id)

    @document.reload
    assert_equal 1, @document.metadata["pages"]
    assert @document.metadata["extracted_at"].present?
    assert @document.metadata["word_count"] > 0
  end

  test "should enqueue embeddings job after successful extraction" do
    mock_text = "Sample text for embedding generation."
    
    PDF::Reader.any_instance.stubs(:pages).returns([
      mock_page_with_text(mock_text)
    ])

    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("pdf content")
    @document.stubs(:file).returns(mock_attachment)
    @document.file.stubs(:attached?).returns(true)

    assert_enqueued_with(job: GenerateEmbeddingsJob, args: [@document.id]) do
      ExtractTextJob.perform_now(@document.id)
    end
  end

  test "should not enqueue embeddings job on failure" do
    # Mock failure
    PDF::Reader.any_instance.stubs(:pages).raises(StandardError.new("Processing failed"))

    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("pdf content")
    @document.stubs(:file).returns(mock_attachment)
    @document.file.stubs(:attached?).returns(true)

    assert_no_enqueued_jobs(only: GenerateEmbeddingsJob) do
      ExtractTextJob.perform_now(@document.id)
    end
  end

  test "should handle text with special characters" do
    special_text = "Text with special characters: áéíóú, ñ, ç, ü, and symbols: @#$%^&*()"
    
    PDF::Reader.any_instance.stubs(:pages).returns([
      mock_page_with_text(special_text)
    ])

    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("pdf content")
    @document.stubs(:file).returns(mock_attachment)
    @document.file.stubs(:attached?).returns(true)

    ExtractTextJob.perform_now(@document.id)

    @document.reload
    chunk = @document.doc_chunks.first
    assert_includes chunk.content, "special characters"
    assert_includes chunk.content, "áéíóú"
  end

  test "should strip and normalize whitespace" do
    messy_text = "  This   has    lots\n\n\nof    whitespace   \t\t  "
    
    PDF::Reader.any_instance.stubs(:pages).returns([
      mock_page_with_text(messy_text)
    ])

    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("pdf content")
    @document.stubs(:file).returns(mock_attachment)
    @document.file.stubs(:attached?).returns(true)

    ExtractTextJob.perform_now(@document.id)

    @document.reload
    chunk = @document.doc_chunks.first
    assert_not_includes chunk.content, "   "  # No triple spaces
    assert_not chunk.content.start_with?(" ")  # No leading space
    assert_not chunk.content.end_with?(" ")    # No trailing space
  end

  test "should handle empty pages gracefully" do
    PDF::Reader.any_instance.stubs(:pages).returns([
      mock_page_with_text(""),
      mock_page_with_text("Some actual content"),
      mock_page_with_text("")
    ])

    mock_attachment = mock('attachment')
    mock_attachment.stubs(:download).returns("pdf content")
    @document.stubs(:file).returns(mock_attachment)
    @document.file.stubs(:attached?).returns(true)

    ExtractTextJob.perform_now(@document.id)

    @document.reload
    assert_equal "processing", @document.status
    chunk = @document.doc_chunks.first
    assert_includes chunk.content, "actual content"
  end

  private

  def mock_page_with_text(text)
    page = mock('page')
    page.stubs(:text).returns(text)
    page
  end
end
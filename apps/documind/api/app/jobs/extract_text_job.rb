class ExtractTextJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Document.find(document_id)
    document.update!(status: 'processing')

    begin
      # Extract text from PDF
      text = extract_text_from_pdf(document.file)
      
      # Chunk the text
      chunks = chunk_text(text)
      
      # Create DocChunk records
      chunks.each_with_index do |chunk_content, index|
        document.doc_chunks.create!(
          content: chunk_content,
          chunk_index: index,
          start_token: index * 700, # Approximate token counting
          end_token: (index + 1) * 700
        )
      end

      # Update document status
      document.update!(
        status: 'completed',
        page_count: extract_page_count(document.file),
        chunk_count: chunks.count
      )

      # Enqueue embedding job
      EmbedChunksJob.perform_later(document_id)

    rescue => e
      Rails.logger.error "Text extraction failed for document #{document_id}: #{e.message}"
      document.update!(status: 'failed')
      raise e
    end
  end

  private

  def extract_text_from_pdf(file)
    require 'pdf-reader'
    require 'tempfile'
    
    text = ""
    
    # Create a temporary file to work with
    Tempfile.create(['pdf_extract', '.pdf']) do |temp_file|
      temp_file.binmode
      temp_file.write(file.download)
      temp_file.rewind
      
      PDF::Reader.open(temp_file.path) do |reader|
        reader.pages.each do |page|
          text += page.text + "\n"
        end
      end
    end
    
    text
  rescue => e
    Rails.logger.error "PDF extraction error: #{e.message}"
    raise "Failed to extract text from PDF: #{e.message}"
  end

  def extract_page_count(file)
    require 'pdf-reader'
    require 'tempfile'
    
    Tempfile.create(['pdf_count', '.pdf']) do |temp_file|
      temp_file.binmode
      temp_file.write(file.download)
      temp_file.rewind
      
      PDF::Reader.open(temp_file.path) do |reader|
        return reader.page_count
      end
    end
  rescue => e
    Rails.logger.error "Page count extraction error: #{e.message}"
    0
  end

  def chunk_text(text, chunk_size: 700, overlap: 100)
    # Simple tokenization (words as tokens)
    tokens = text.split(/\s+/)
    chunks = []
    
    i = 0
    while i < tokens.length
      chunk_tokens = tokens[i, chunk_size]
      chunks << chunk_tokens.join(' ')
      i += chunk_size - overlap
    end
    
    chunks
  end
end 
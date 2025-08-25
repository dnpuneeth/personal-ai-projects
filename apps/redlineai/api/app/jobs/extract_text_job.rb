class ExtractTextJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    Rails.logger.info "Starting text extraction for document #{document_id}"
    
    document = Document.find(document_id)
    document.update!(status: 'processing')

    begin
      # Log memory usage before processing
      Rails.logger.info "Memory before processing: #{get_memory_usage}"
      
      # Extract text based on file type
      text = extract_text_from_file(document.file)
      Rails.logger.info "Text extracted, length: #{text.length} characters"
      
      # Log memory usage after text extraction
      Rails.logger.info "Memory after text extraction: #{get_memory_usage}"
      
      # Chunk the text
      chunks = chunk_text(text)
      Rails.logger.info "Text chunked into #{chunks.count} chunks"
      
      # Create DocChunk records in batches to avoid memory issues
      chunks.each_with_index do |chunk_content, index|
        document.doc_chunks.create!(
          content: chunk_content,
          chunk_index: index,
          start_token: index * 500, # Approximate token counting (reduced chunk size)
          end_token: (index + 1) * 500
        )
        
        # Force garbage collection every 5 chunks for aggressive memory management
        GC.start if index % 5 == 0
      end
      
      Rails.logger.info "Created #{chunks.count} doc chunks"

      # Update document status
      page_count = extract_page_count(document.file)
      document.update!(
        status: 'completed',
        page_count: page_count,
        chunk_count: chunks.count
      )

      Rails.logger.info "Document #{document_id} processing completed successfully"
      
      # Enqueue embedding job
      EmbedChunksJob.perform_later(document_id)

    rescue => e
      Rails.logger.error "Text extraction failed for document #{document_id}: #{e.class.name} - #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
      
      begin
        document.update!(status: 'failed')
      rescue => update_error
        Rails.logger.error "Failed to update document status: #{update_error.message}"
      end
      
      # Don't re-raise the error to prevent app crashes
      Rails.logger.error "Job failed but not re-raising to prevent app crash"
    ensure
      # Force garbage collection
      GC.start
      Rails.logger.info "Memory after processing: #{get_memory_usage}"
    end
  end

  private

  def get_memory_usage
    if File.exist?('/proc/meminfo')
      # Linux memory info
      meminfo = File.read('/proc/meminfo')
      if match = meminfo.match(/MemAvailable:\s+(\d+)\s+kB/)
        available_mb = match[1].to_i / 1024
        "#{available_mb}MB available"
      else
        "unknown"
      end
    else
      # Fallback for other systems
      "#{`ps -o rss= -p #{Process.pid}`.to_i / 1024}MB RSS"
    end
  rescue
    "unknown"
  end

  private

  def extract_text_from_file(file)
    # Determine file type by content type or filename
    content_type = file.content_type
    filename = file.filename.to_s.downcase
    
    if content_type == 'application/pdf' || filename.end_with?('.pdf')
      extract_text_from_pdf(file)
    elsif content_type == 'text/plain' || filename.end_with?('.txt')
      extract_text_from_txt(file)
    else
      raise "Unsupported file type: #{content_type}"
    end
  end

  def extract_text_from_txt(file)
    # Read the text file content directly
    file.download
  rescue => e
    Rails.logger.error "TXT extraction error: #{e.message}"
    raise "Failed to extract text from TXT file: #{e.message}"
  end

  def extract_text_from_pdf(file)
    require 'pdf-reader'
    require 'tempfile'
    
    text = ""
    
    # Create a temporary file to work with
    Tempfile.create(['pdf_extract', '.pdf']) do |temp_file|
      temp_file.binmode
      
      # Stream the file content to avoid loading entire file into memory
      file.open do |file_io|
        IO.copy_stream(file_io, temp_file)
      end
      temp_file.rewind
      
      PDF::Reader.open(temp_file.path) do |reader|
        Rails.logger.info "Processing PDF with #{reader.page_count} pages"
        
        # Limit processing to reasonable number of pages to prevent memory issues
        # Reduced for Koyeb's 512MB memory limit
        max_pages = 50
        pages_to_process = [reader.page_count, max_pages].min
        
        if reader.page_count > max_pages
          Rails.logger.warn "PDF has #{reader.page_count} pages, limiting to #{max_pages} for processing"
        end
        
        (1..pages_to_process).each do |page_num|
          begin
            page = reader.page(page_num)
            page_text = page.text
            text += page_text + "\n"
            
            # Force GC every 5 pages to manage memory more aggressively
            GC.start if page_num % 5 == 0
            
            Rails.logger.debug "Processed page #{page_num}/#{pages_to_process}"
          rescue => page_error
            Rails.logger.warn "Failed to extract text from page #{page_num}: #{page_error.message}"
            # Continue with other pages
          end
        end
      end
    end
    
    if text.strip.empty?
      raise "No extractable text found in PDF"
    end
    
    text
  rescue => e
    Rails.logger.error "PDF extraction error: #{e.class.name} - #{e.message}"
    raise "Failed to extract text from PDF: #{e.message}"
  end

  def extract_page_count(file)
    content_type = file.content_type
    filename = file.filename.to_s.downcase
    
    if content_type == 'application/pdf' || filename.end_with?('.pdf')
      extract_pdf_page_count(file)
    elsif content_type == 'text/plain' || filename.end_with?('.txt')
      # For text files, we can estimate pages based on character count
      # Assuming ~3000 characters per page (rough estimate)
      text_content = file.download
      estimated_pages = [1, (text_content.length / 3000.0).ceil].max
      estimated_pages
    else
      0
    end
  rescue => e
    Rails.logger.error "Page count extraction error: #{e.message}"
    0
  end

  def extract_pdf_page_count(file)
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
    Rails.logger.error "PDF page count extraction error: #{e.message}"
    0
  end

  def chunk_text(text, chunk_size: 500, overlap: 50)
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
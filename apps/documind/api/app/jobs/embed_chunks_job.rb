class EmbedChunksJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Document.find(document_id)
    embeddings_service = EmbeddingsService.new

    begin
      # Get chunks without embeddings
      chunks = document.doc_chunks.where(embedding: nil).ordered
      
      return if chunks.empty?

      # Prepare texts for embedding
      texts = chunks.map(&:content)
      
      # Get embeddings
      embeddings = embeddings_service.embed_batch(texts)
      
      # Update chunks with embeddings
      chunks.each_with_index do |chunk, index|
        # Convert array to pgvector format
        embedding_string = "[#{embeddings[index].join(',')}]"
        chunk.update!(embedding: embedding_string)
      end

      # Track AI event
      document.ai_events.create!(
        event_type: 'embedding',
        model: ENV.fetch('EMBEDDING_MODEL', 'text-embedding-3-small'),
        tokens_used: texts.sum { |text| text.split.length },
        latency_ms: 0, # Will be calculated by the service
        cost_cents: calculate_embedding_cost(texts.length),
        metadata: { chunks_processed: chunks.count }
      )

      Rails.logger.info "Embedded #{chunks.count} chunks for document #{document_id}"

    rescue => e
      Rails.logger.error "Embedding failed for document #{document_id}: #{e.message}"
      raise e
    end
  end

  private

  def calculate_embedding_cost(token_count)
    # OpenAI text-embedding-3-small: $0.00002 per 1K tokens
    # Convert to cents
    ((token_count / 1000.0) * 0.00002 * 100).round
  end
end 
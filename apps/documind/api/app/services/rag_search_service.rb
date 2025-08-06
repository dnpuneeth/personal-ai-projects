class RagSearchService
  def initialize(embeddings_service = EmbeddingsService.new)
    @embeddings_service = embeddings_service
  end

  def search(query, document_id: nil, top_k: 12, threshold: 2.0)
    start_time = Time.current
    
    # Get query embedding
    query_embedding = @embeddings_service.embed_single(query)
    
    # Search for similar chunks
    chunks = search_chunks(query_embedding, document_id, top_k, threshold)
    
    # Calculate search metrics
    latency_ms = ((Time.current - start_time) * 1000).round
    
    # Return results with metadata
    {
      chunks: chunks,
      query: query,
      total_chunks: chunks.count,
      latency_ms: latency_ms,
      query_embedding: query_embedding
    }
  rescue => e
    Rails.logger.error "RAG search error: #{e.message}"
    raise e
  end

  private

  def search_chunks(query_embedding, document_id, top_k, threshold)
    scope = DocChunk.where.not(embedding: nil)
    scope = scope.where(document_id: document_id) if document_id
    
    scope.similarity_search(query_embedding, threshold: threshold, limit: top_k)
         .includes(:document)
         .ordered
  end
end 
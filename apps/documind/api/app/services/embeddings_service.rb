class EmbeddingsService
  include HTTParty
  base_uri 'https://api.openai.com/v1'

  def initialize
    @api_key = ENV['OPENAI_API_KEY']
    @model = ENV.fetch('EMBEDDING_MODEL', 'text-embedding-3-small')
    @dimensions = 1536 # Default for text-embedding-3-small
  end

  def call(texts)
    return [] if texts.empty?

    response = self.class.post('/embeddings',
      headers: {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'application/json'
      },
      body: {
        input: texts,
        model: @model,
        dimensions: @dimensions
      }.to_json
    )

    if response.success?
      response['data'].map { |item| item['embedding'] }
    else
      Rails.logger.error "Embedding API error: #{response.code} - #{response.body}"
      raise "Embedding API error: #{response.code}"
    end
  rescue => e
    Rails.logger.error "Embedding service error: #{e.message}"
    raise e
  end

  def embed_single(text)
    call([text]).first
  end

  def embed_batch(texts, batch_size: 100)
    results = []
    texts.each_slice(batch_size) do |batch|
      results.concat(call(batch))
    end
    results
  end
end 
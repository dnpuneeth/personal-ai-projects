class DocChunk < ApplicationRecord
  belongs_to :document

  validates :content, presence: true
  validates :chunk_index, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :start_token, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :end_token, presence: true, numericality: { only_integer: true, greater_than: :start_token }

  scope :ordered, -> { order(:chunk_index) }

  # Vector similarity search
  def self.nearest_neighbors(query_embedding, limit: 12)
    # Convert query embedding to pgvector format
    query_vector = "[#{query_embedding.join(',')}]"
    
    where.not(embedding: nil)
         .order(Arel.sql("embedding <-> '#{query_vector}'::vector"))
         .limit(limit)
  end

  def self.similarity_search(query_embedding, threshold: 2.0, limit: 12)
    # Convert query embedding to pgvector format
    query_vector = "[#{query_embedding.join(',')}]"
    
    where.not(embedding: nil)
         .where(Arel.sql("embedding <-> '#{query_vector}'::vector < #{threshold}"))
         .order(Arel.sql("embedding <-> '#{query_vector}'::vector"))
         .limit(limit)
  end
end

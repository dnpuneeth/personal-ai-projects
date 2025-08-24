class AiEvent < ApplicationRecord
  belongs_to :document, optional: true
  belongs_to :deleted_document, optional: true

  validates :event_type, presence: true, inclusion: { in: %w[embedding summarization question_answering redlining] }
  validates :model, presence: true
  validates :tokens_used, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :latency_ms, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :cost_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  validate :document_or_deleted_document_present

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :by_model, ->(model) { where(model: model) }

  def cost_dollars
    cost_cents / 100.0
  end

  def latency_seconds
    latency_ms / 1000.0
  end
  
  def document_title
    document&.title || deleted_document&.title || 'Unknown Document'
  end
  
  def document_display_name
    document&.display_name || deleted_document&.display_name || 'Unknown Document'
  end
  
  private
  
  def document_or_deleted_document_present
    unless document.present? || deleted_document.present?
      errors.add(:base, 'Either document or deleted_document must be present')
    end
  end
end

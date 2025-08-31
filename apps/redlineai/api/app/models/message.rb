class Message < ApplicationRecord
  belongs_to :conversation

  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  validates :content, presence: true

  scope :user_messages, -> { where(role: 'user') }
  scope :assistant_messages, -> { where(role: 'assistant') }
  scope :recent, -> { order(created_at: :desc) }

  def user_message?
    role == 'user'
  end

  def assistant_message?
    role == 'assistant'
  end

  def cost_dollars
    cost_cents / 100.0
  end

  def display_time
    created_at.strftime("%I:%M %p")
  end

  def display_date
    created_at.strftime("%b %d, %Y")
  end

  def citations
    metadata['citations'] || []
  end

  def confidence
    metadata['confidence']
  end

  def has_citations?
    citations.any?
  end

  def has_confidence?
    confidence.present?
  end

  def cached?
    metadata&.dig('cached') == true
  end
end

class Conversation < ApplicationRecord
  belongs_to :document
  belongs_to :user, optional: true
  has_many :messages, dependent: :destroy

  validates :title, presence: true
  validates :expires_at, presence: true
  
  before_validation :ensure_expires_at_set

  scope :active, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :recent, -> { order(last_message_at: :desc) }

  before_create :set_default_expiry
  after_create :create_welcome_message

  def active?
    expires_at > Time.current
  end

  def expired?
    expires_at <= Time.current
  end

  def total_cost_dollars
    total_cost_cents / 100.0
  end

  def can_add_message?
    return false if expired?

    # Limit conversation length based on user tier
    if user&.subscription&.pro?
      message_count < 50  # Pro users get 50 messages
    else
      message_count < 20  # Free users get 20 messages
    end
  end

  def add_message(role:, content:, tokens_used: 0, cost_cents: 0, metadata: {})
    return false unless can_add_message?

    message = messages.create!(
      role: role,
      content: content,
      tokens_used: tokens_used,
      cost_cents: cost_cents,
      metadata: metadata
    )

    if message.persisted?
      update!(
        message_count: message_count + 1,
        total_tokens_used: total_tokens_used + tokens_used,
        total_cost_cents: total_cost_cents + cost_cents,
        last_message_at: Time.current
      )

      # Extend expiry for active conversations
      if active? && message_count % 5 == 0  # Extend every 5 messages
        extend_expiry
      end
    end

    message
  end

  def extend_expiry
    new_expiry = if user&.subscription&.pro?
                   30.days.from_now
                 else
                   1.day.from_now
                 end

    update!(expires_at: new_expiry)
  end

  def conversation_context
    # Get last 3 messages for context (aggressively reduced to save tokens)
    messages.order(created_at: :desc).limit(3).reverse
  end

  def conversation_context_short
    # Get last 2 messages for very long conversations
    messages.order(created_at: :desc).limit(2).reverse
  end

  def cleanup_expired
    return unless expired?

    # Soft delete by setting expired status
    update!(expires_at: 1.minute.ago)
  end

  private

  def ensure_expires_at_set
    if self.expires_at.blank?
      self.expires_at = if user&.subscription&.pro?
                          30.days.from_now
                        else
                          1.day.from_now
                        end
    end
  end

  def set_default_expiry
    if self.expires_at.blank?
      self.expires_at = if user&.subscription&.pro?
                          30.days.from_now
                        else
                          1.day.from_now
                        end
    end
  end

  def create_welcome_message
    messages.create!(
      role: 'assistant',
      content: "Hello! I'm here to help you analyze this document. You can ask me questions about the content, request summaries, or discuss specific sections. What would you like to know?",
      tokens_used: 0,
      cost_cents: 0,
      metadata: { type: 'welcome' }
    )
  end
end

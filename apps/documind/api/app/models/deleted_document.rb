class DeletedDocument < ApplicationRecord
  belongs_to :user, optional: true
  has_many :ai_events, dependent: :destroy
  
  validates :original_document_id, presence: true
  validates :title, presence: true
  validates :deleted_at, presence: true
  validates :total_cost_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_tokens_used, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :ai_events_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :recent, -> { order(deleted_at: :desc) }
  scope :this_month, -> { where(deleted_at: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :last_month, -> { where(deleted_at: 1.month.ago.beginning_of_month..1.month.ago.end_of_month) }
  scope :anonymous, -> { where(user_id: nil) }
  scope :with_user, -> { where.not(user_id: nil) }
  
  def total_cost_dollars
    total_cost_cents / 100.0
  end
  
  def display_name
    title
  end
  
  def is_pdf?
    file_type == 'pdf'
  end
  
  def is_txt?
    file_type == 'txt'
  end
  
  def average_cost_per_event
    return 0.0 if ai_events_count == 0
    total_cost_dollars / ai_events_count
  end
  
  def user_email
    user&.email || 'Anonymous User'
  end
  
  def anonymous?
    user.nil?
  end
end

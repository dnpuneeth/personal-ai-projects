class TempAiResult < ApplicationRecord
  belongs_to :document
  
  validates :event_type, presence: true
  validates :result_data, presence: true
  validates :expires_at, presence: true
  
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :active, -> { where('expires_at > ?', Time.current) }
  
  def expired?
    expires_at < Time.current
  end
  
  def active?
    !expired?
  end
end

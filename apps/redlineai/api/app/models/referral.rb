class Referral < ApplicationRecord
  belongs_to :referrer, class_name: 'User'
  belongs_to :referred, class_name: 'User'
  
  validates :referrer_id, presence: true
  validates :referred_id, presence: true
  validates :code, presence: true, uniqueness: true
  
  before_validation :generate_code, on: :create
  
  scope :successful, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
  
  def self.generate_referral_code
    SecureRandom.alphanumeric(8).upcase
  end
  
  def complete!
    update!(status: 'completed', completed_at: Time.current)
    
    # Give referrer a bonus (e.g., extra documents for the month)
    referrer.subscription&.update_column(:bonus_documents, referrer.subscription.bonus_documents.to_i + 5)
  end
  
  private
  
  def generate_code
    self.code = self.class.generate_referral_code
  end
end

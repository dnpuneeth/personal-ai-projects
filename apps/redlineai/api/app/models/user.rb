class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2]

  # Associations
  has_many :documents, dependent: :destroy
  has_many :ai_events, through: :documents
  has_many :deleted_documents, dependent: :destroy

  # Active Storage for profile pictures
  has_one_attached :profile_picture

  # Validations
  validates :name, presence: true, if: :oauth_user?
  validates :email, presence: true, uniqueness: true
  validates :public_id, presence: true, uniqueness: true

  # Profile picture validation
  validate :acceptable_profile_picture

  # Callbacks
  before_create :generate_public_id

  # Usage limits for anonymous users
  ANONYMOUS_DOCUMENT_LIMIT = 1
  ANONYMOUS_AI_ACTION_LIMIT = 3

  # Class methods
  def self.find_by_public_id(public_id)
    find_by(public_id: public_id)
  end

  def self.find_by_public_id!(public_id)
    find_by!(public_id: public_id)
  end

  # OAuth methods
  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.avatar_url = auth.info.image
      user.provider = auth.provider
      user.uid = auth.uid
    end
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  def google_user?
    provider == 'google_oauth2'
  end

  def display_name
    name.presence || email.split('@').first
  end

  # Profile picture methods
  def profile_picture_url
    if profile_picture.attached?
      profile_picture
    elsif avatar_url.present?
      avatar_url
    else
      nil
    end
  end

  def has_profile_picture?
    profile_picture.attached? || avatar_url.present?
  end

  def profile_picture_thumbnail
    if profile_picture.attached?
      profile_picture.variant(resize_to_fill: [100, 100]).processed
    else
      nil
    end
  end

  # Usage tracking methods
  def increment_documents_uploaded!
    increment!(:documents_uploaded)
    touch(:last_activity_at)
  end

  def increment_ai_actions_used!
    increment!(:ai_actions_used)
    touch(:last_activity_at)
  end

  def can_upload_document?
    true # Authenticated users have unlimited uploads
  end

  def can_perform_ai_action?
    true # Authenticated users have unlimited AI actions
  end

  def total_cost_cents
    ai_events.sum(:cost_cents) + deleted_documents.sum(:total_cost_cents)
  end

  def total_tokens_used
    ai_events.sum(:tokens_used) + deleted_documents.sum(:total_tokens_used)
  end

  def total_documents_count
    documents.count + deleted_documents.count
  end

  def total_ai_events_count
    ai_events.count + deleted_documents.sum(:ai_events_count)
  end

  def deleted_documents_count
    deleted_documents.count
  end

  def deleted_documents_cost_cents
    deleted_documents.sum(:total_cost_cents)
  end

  def deleted_documents_tokens
    deleted_documents.sum(:total_tokens_used)
  end

  # Activity tracking
  def active_recently?
    last_activity_at && last_activity_at > 30.days.ago
  end

  def update_activity!
    touch(:last_activity_at)
  end

  private

  def generate_public_id
    loop do
      self.public_id = SecureRandom.urlsafe_base64(12)
      break unless User.exists?(public_id: public_id)
    end
  end

  def acceptable_profile_picture
    return unless profile_picture.attached?

    unless profile_picture.content_type.in?(%w[image/png image/jpeg image/jpg image/gif])
      errors.add(:profile_picture, 'must be a valid image format (PNG, JPEG, JPG, or GIF)')
    end

    unless profile_picture.byte_size <= 5.megabytes
      errors.add(:profile_picture, 'must be less than 5MB')
    end
  end
end

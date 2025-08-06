class Document < ApplicationRecord
  has_one_attached :file
  has_many :doc_chunks, dependent: :destroy
  has_many :ai_events, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: 'completed') }
  scope :processing, -> { where(status: 'processing') }
  scope :failed, -> { where(status: 'failed') }

  def completed?
    status == 'completed'
  end

  def processing?
    status == 'processing'
  end

  def failed?
    status == 'failed'
  end

  def pending?
    status == 'pending'
  end
end

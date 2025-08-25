class Document < ApplicationRecord
  # Associations
  belongs_to :user, optional: true  # Allow anonymous documents
  has_one_attached :file
  has_many :doc_chunks, dependent: :destroy
  has_many :ai_events, dependent: :nullify
  has_many :temp_ai_results, dependent: :destroy

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

  def filename
    file.attached? ? file.filename.to_s : title
  end

  def display_name
    filename.presence || title
  end

  def file_type
    return 'unknown' unless file.attached?
    
    content_type = file.content_type
    filename_ext = file.filename.to_s.downcase
    
    if content_type == 'application/pdf' || filename_ext.end_with?('.pdf')
      'pdf'
    elsif content_type == 'text/plain' || filename_ext.end_with?('.txt')
      'txt'
    else
      'unknown'
    end
  end

  def is_pdf?
    file_type == 'pdf'
  end

  def is_txt?
    file_type == 'txt'
  end

  def page_count
    # For PDFs, try to get page count from metadata
    # For now, return a default value or calculate from chunks
    if is_pdf? && doc_chunks.any?
      # Estimate pages based on chunk count (rough approximation)
      # In a real implementation, you'd extract this from PDF metadata
      [(doc_chunks.count / 2.0).ceil, 1].max
    else
      1
    end
  end

  def chunk_count
    doc_chunks.count
  end

  def cleanup_temp_ai_results
    temp_ai_results.expired.delete_all
  end
end

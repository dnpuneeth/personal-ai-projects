class Document < ApplicationRecord
  # Associations
  belongs_to :user, optional: true  # Allow anonymous documents
  has_one_attached :file
  has_many :doc_chunks, dependent: :destroy
  has_many :ai_events, dependent: :nullify
  has_many :temp_ai_results, dependent: :destroy
  has_many :conversations, dependent: :destroy

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

  def can_show_pdf_preview?
    is_pdf? && file.attached? && file.content_type == 'application/pdf'
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

  def content_preview(max_chunks: 15, max_length: 2000)
    return "" unless doc_chunks.any?

    # Combine chunks into a readable preview
    preview_chunks = doc_chunks.ordered.limit(max_chunks)
    preview_content = preview_chunks.map(&:content).join(' ')

    # Clean up the content for better readability
    preview_content = preview_content.gsub(/\s+/, ' ').strip

    # Truncate to max length, trying to break at word boundaries
    if preview_content.length > max_length
      truncated = preview_content[0...max_length]
      # Try to find the last complete word
      last_space = truncated.rindex(' ')
      if last_space && last_space > max_length * 0.8
        truncated = truncated[0...last_space]
      end
      preview_content = truncated + "..."
    end

    preview_content
  end

  def chunk_count
    doc_chunks.count
  end

  def cleanup_temp_ai_results
    temp_ai_results.expired.delete_all
  end

  def get_or_create_conversation(user = nil)
    # Find active conversation or create new one
    conversation = conversations.active.find_by(user: user)

    unless conversation
      title = "Chat about #{display_name}"
      expires_at = if user&.subscription&.pro?
                     30.days.from_now
                   else
                     1.day.from_now
                   end

      conversation = conversations.create!(
        title: title,
        user: user,
        expires_at: expires_at
      )
    end

    conversation
  end

  def active_conversation_for_user(user = nil)
    conversations.active.find_by(user: user)
  end
end

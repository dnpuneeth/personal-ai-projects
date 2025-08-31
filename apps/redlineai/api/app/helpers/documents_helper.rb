module DocumentsHelper
  def document_summary_info(document)
    return "Processing..." unless document.completed?

    info_parts = []

    # Page count
    info_parts << pluralize(document.page_count, 'page')

    # File type
    info_parts << document.file_type.upcase

    # File size if available
    if document.file.attached? && document.file.byte_size.present?
      info_parts << number_to_human_size(document.file.byte_size)
    end

    # AI insights count
    ai_count = document.ai_insights_count
    if ai_count > 0
      info_parts << pluralize(ai_count, 'AI insight')
    end

    info_parts.join(' • ')
  end

    def document_processing_time(document)
    return nil unless document.completed? && document.updated_at && document.created_at

    processing_time = document.updated_at - document.created_at
    if processing_time < 60
      "#{processing_time.round} seconds"
    elsif processing_time < 3600
      "#{(processing_time / 60).round} minutes"
    else
      "#{(processing_time / 3600).round(1)} hours"
    end
  end

  def ai_analysis_summary(document)
    return nil unless document.completed? && document.ai_events.any?

    types = document.ai_analysis_types
    return nil if types.empty?

    # Convert technical names to user-friendly descriptions
    friendly_types = types.map do |type|
      case type
      when 'summarization'
        'Summary'
      when 'question_answering'
        'Q&A'
      when 'redlining'
        'Redlines'
      when 'embedding'
        'Search'
      else
        type.titleize
      end
    end

    "AI analyzed: #{friendly_types.join(', ')}"
  end
end

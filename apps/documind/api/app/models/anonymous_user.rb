class AnonymousUser
  attr_reader :session

  def initialize(session)
    @session = session
  end

  def id
    session[:anonymous_id]
  end

  def email
    nil
  end

  def name
    "Anonymous User"
  end

  def display_name
    "Anonymous User"
  end

  def documents_uploaded
    session[:anonymous_documents_count].to_i
  end

  def ai_actions_used
    session[:anonymous_ai_actions_count].to_i
  end

  def can_upload_document?
    documents_uploaded < User::ANONYMOUS_DOCUMENT_LIMIT
  end

  def can_perform_ai_action?
    ai_actions_used < User::ANONYMOUS_AI_ACTION_LIMIT
  end

  def documents_remaining
    [User::ANONYMOUS_DOCUMENT_LIMIT - documents_uploaded, 0].max
  end

  def ai_actions_remaining
    [User::ANONYMOUS_AI_ACTION_LIMIT - ai_actions_used, 0].max
  end

  def usage_summary
    {
      documents: {
        used: documents_uploaded,
        limit: User::ANONYMOUS_DOCUMENT_LIMIT,
        remaining: documents_remaining
      },
      ai_actions: {
        used: ai_actions_used,
        limit: User::ANONYMOUS_AI_ACTION_LIMIT,
        remaining: ai_actions_remaining
      }
    }
  end

  def authenticated?
    false
  end

  def anonymous?
    true
  end

  def persisted?
    false
  end

  def oauth_user?
    false
  end

  def google_user?
    false
  end
end
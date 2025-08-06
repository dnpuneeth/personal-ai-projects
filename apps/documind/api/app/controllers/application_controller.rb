class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user_or_track_anonymous!
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # Make helper methods available to views
  helper_method :anonymous_user?, :current_user_or_anonymous
  
  protected

  def authenticate_user_or_track_anonymous!
    unless user_signed_in?
      # Track anonymous session
      session[:anonymous_id] ||= SecureRandom.uuid
      session[:anonymous_documents_count] ||= 0
      session[:anonymous_ai_actions_count] ||= 0
    else
      current_user.update_activity!
    end
  end

  def anonymous_user?
    !user_signed_in?
  end

  def current_user_or_anonymous
    user_signed_in? ? current_user : AnonymousUser.new(session)
  end

  def check_document_upload_limit!
    if anonymous_user?
      if session[:anonymous_documents_count].to_i >= User::ANONYMOUS_DOCUMENT_LIMIT
        respond_to do |format|
          format.html do
            flash[:alert] = "Anonymous users can only upload #{User::ANONYMOUS_DOCUMENT_LIMIT} document. Please sign in for unlimited uploads."
            redirect_to new_user_session_path
          end
          format.json do
            render json: { 
              error: "Upload limit reached. Please sign in for unlimited uploads.",
              limit: User::ANONYMOUS_DOCUMENT_LIMIT,
              current_count: session[:anonymous_documents_count].to_i
            }, status: :forbidden
          end
        end
        return false
      end
    end
    true
  end

  def check_ai_action_limit!
    if anonymous_user?
      if session[:anonymous_ai_actions_count].to_i >= User::ANONYMOUS_AI_ACTION_LIMIT
        respond_to do |format|
          format.html do
            flash[:alert] = "Anonymous users can only perform #{User::ANONYMOUS_AI_ACTION_LIMIT} AI actions. Please sign in for unlimited access."
            redirect_to new_user_session_path
          end
          format.json do
            render json: { 
              error: "AI action limit reached. Please sign in for unlimited access.",
              limit: User::ANONYMOUS_AI_ACTION_LIMIT,
              current_count: session[:anonymous_ai_actions_count].to_i
            }, status: :forbidden
          end
        end
        return false
      end
    end
    true
  end

  def increment_anonymous_document_count!
    if anonymous_user?
      session[:anonymous_documents_count] = session[:anonymous_documents_count].to_i + 1
    else
      current_user.increment_documents_uploaded!
    end
  end

  def increment_anonymous_ai_action_count!
    if anonymous_user?
      session[:anonymous_ai_actions_count] = session[:anonymous_ai_actions_count].to_i + 1
    else
      current_user.increment_ai_actions_used!
    end
  end

  def decrement_anonymous_document_count!
    if session[:anonymous_documents_count] && session[:anonymous_documents_count].to_i > 0
      session[:anonymous_documents_count] = [session[:anonymous_documents_count].to_i - 1, 0].max
      Rails.logger.info "Decremented anonymous document count to #{session[:anonymous_documents_count]}"
    else
      Rails.logger.info "Cannot decrement anonymous document count: #{session[:anonymous_documents_count]}"
    end
  end

  def decrement_anonymous_ai_action_count!
    if anonymous_user? && session[:anonymous_ai_actions_count]
      session[:anonymous_ai_actions_count] = [session[:anonymous_ai_actions_count].to_i - 1, 0].max
      Rails.logger.info "Decremented anonymous AI action count to #{session[:anonymous_ai_actions_count]}"
    end
  end

  def document_belongs_to_anonymous_session?(document)
    document.user.nil? && session[:anonymous_document_ids]&.include?(document.id)
  end

  def store_location_for_login
    session[:return_to] = request.fullpath if request.get? && !request.xhr?
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:remember_me])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end

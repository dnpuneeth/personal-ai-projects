class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:google_oauth2]

  def google_oauth2
    # Check if OAuth data is present
    unless request.env["omniauth.auth"]
      flash[:alert] = "Google OAuth is not properly configured. Please use email/password sign-in."
      redirect_to new_user_session_path
      return
    end

    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      @user.update_activity!
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.google_data"] = request.env["omniauth.auth"].except("extra")
      flash[:alert] = "There was an issue signing you in with Google. Please try again."
      redirect_to new_user_registration_url
    end
  end

  def passthru
    # Handle the passthru case when OAuth isn't configured
    flash[:alert] = "Google OAuth is not configured. Please use email/password sign-in or contact support."
    redirect_to new_user_session_path
  end

  def failure
    flash[:alert] = "Authentication failed. Please try again."
    redirect_to new_user_session_path
  end

  protected

  def after_omniauth_failure_path_for(scope)
    new_user_session_path
  end

  def after_sign_in_path_for(resource)
    if session[:return_to].present?
      session.delete(:return_to)
    else
      root_path
    end
  end
end
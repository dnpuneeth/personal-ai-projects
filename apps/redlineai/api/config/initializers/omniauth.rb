Rails.application.config.middleware.use OmniAuth::Builder do
  # Check if Google OAuth credentials are present
  if ENV['GOOGLE_CLIENT_ID'].present? && ENV['GOOGLE_CLIENT_SECRET'].present?
    provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'],
             {
               scope: 'email,profile',
               prompt: 'select_account',
               image_aspect_ratio: 'square',
               image_size: 50
             }
  else
    Rails.logger.warn "Google OAuth credentials not configured. Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET environment variables."
  end
end

# Configure OmniAuth to handle CSRF protection
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
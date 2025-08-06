# Sentry configuration for error tracking
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set traces_sample_rate to 1.0 to capture 100% of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', 0.1).to_f

  # Enable performance monitoring
  config.enable_tracing = true

  # Filter out sensitive data
  config.before_send = lambda do |event, hint|
    # Remove PII from logs
    if event.request && event.request.data
      event.request.data = event.request.data.gsub(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/, '[EMAIL]')
    end
    event
  end

  # Set environment
  config.environment = Rails.env
end 
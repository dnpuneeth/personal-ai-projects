# Sidekiq configuration
Sidekiq.configure_server do |config|
  # Use Upstash-compatible Redis configuration
  # Parse the Redis URL manually to avoid protocol parsing issues
  redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'
  
  if redis_url.start_with?('rediss://')
    # For TLS connections, use ssl: true and parse the URL properly
    uri = URI.parse(redis_url)
    config.redis = {
      host: uri.host,
      port: uri.port,
      username: uri.user,
      password: uri.password,
      ssl: true,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
      network_timeout: 10
    }
  else
    # For non-TLS connections, use the URL directly
    config.redis = { 
      url: redis_url,
      network_timeout: 10
    }
  end
  
  # Configure logging
  config.logger.level = Logger::INFO
  
  # Configure concurrency
  config.concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', 5).to_i
end

Sidekiq.configure_client do |config|
  # Use Upstash-compatible Redis configuration
  # Parse the Redis URL manually to avoid protocol parsing issues
  redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'
  
  if redis_url.start_with?('rediss://')
    # For TLS connections, use ssl: true and parse the URL properly
    uri = URI.parse(redis_url)
    config.redis = {
      host: uri.host,
      port: uri.port,
      username: uri.user,
      password: uri.password,
      ssl: true,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
      network_timeout: 10
    }
  else
    # For non-TLS connections, use the URL directly
    config.redis = { 
      url: redis_url,
      network_timeout: 10
    }
  end
end

# Note: Queue adapter is set in environment-specific configs
# Production uses :sidekiq, development/test can use :sidekiq 
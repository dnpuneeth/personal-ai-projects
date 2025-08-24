# Sidekiq configuration
Sidekiq.configure_server do |config|
  redis_config = { 
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    # Better connection settings for Upstash
    network_timeout: 10,
    pool_timeout: 10,
    # Add TLS support for Upstash
    ssl: true,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    # Connection retry settings
    reconnect_attempts: 5,
    reconnect_delay: 1.0,
    reconnect_delay_max: 5.0,
    # Connection pool settings
    pool_size: 10,
    pool_timeout: 10
  }
  
  # Try to configure Redis with fallback
  begin
    config.redis = redis_config
  rescue => e
    Rails.logger.warn "Failed to configure Redis with TLS, trying without: #{e.message}"
    # Fallback without TLS
    config.redis = { 
      url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
      network_timeout: 10,
      pool_timeout: 10,
      reconnect_attempts: 5
    }
  end
  
  # Configure logging
  config.logger.level = Logger::INFO
  
  # Configure concurrency
  config.concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', 5).to_i
end

Sidekiq.configure_client do |config|
  redis_config = { 
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    # Better connection settings for Upstash
    network_timeout: 10,
    pool_timeout: 10,
    # Add TLS support for Upstash
    ssl: true,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    # Connection retry settings
    reconnect_attempts: 5,
    reconnect_delay: 1.0,
    reconnect_delay_max: 5.0,
    # Connection pool settings
    pool_size: 10,
    pool_timeout: 10
  }
  
  # Try to configure Redis with fallback
  begin
    config.redis = redis_config
  rescue => e
    Rails.logger.warn "Failed to configure Redis with TLS, trying without: #{e.message}"
    # Fallback without TLS
    config.redis = { 
      url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
      network_timeout: 10,
      pool_timeout: 10,
      reconnect_attempts: 5
    }
  end
end

# Note: Queue adapter is set in environment-specific configs
# Production uses :sidekiq, development/test can use :sidekiq 
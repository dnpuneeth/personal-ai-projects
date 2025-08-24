# Sidekiq configuration
Sidekiq.configure_server do |config|
  config.redis = { 
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    # Basic connection settings
    network_timeout: 10,
    pool_timeout: 10
  }
  
  # Configure logging
  config.logger.level = Logger::INFO
  
  # Configure concurrency
  config.concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', 5).to_i
end

Sidekiq.configure_client do |config|
  config.redis = { 
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    # Basic connection settings
    network_timeout: 10,
    pool_timeout: 10
  }
end

# Note: Queue adapter is set in environment-specific configs
# Production uses :sidekiq, development/test can use :sidekiq 
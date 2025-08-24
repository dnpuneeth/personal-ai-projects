# Sidekiq configuration
Sidekiq.configure_server do |config|
  # Use only basic, guaranteed-to-work Redis options
  config.redis = { 
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    network_timeout: 10
  }
  
  # Configure logging
  config.logger.level = Logger::INFO
  
  # Configure concurrency
  config.concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', 5).to_i
end

Sidekiq.configure_client do |config|
  # Use only basic, guaranteed-to-work Redis options
  config.redis = { 
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    network_timeout: 10
  }
end

# Note: Queue adapter is set in environment-specific configs
# Production uses :sidekiq, development/test can use :sidekiq 
# Sidekiq configuration
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
  
  # Configure logging
  config.logger.level = Logger::INFO
  
  # Configure concurrency
  config.concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', 5).to_i
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
end

# Set Active Job to use Sidekiq
Rails.application.config.active_job.queue_adapter = :sidekiq 
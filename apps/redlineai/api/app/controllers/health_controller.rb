class HealthController < ApplicationController
  def show
    # Simple health check that doesn't depend on external services
    # This allows Koyeb to verify the app is running without blocking on DB/Redis
    health_status = {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      message: 'Application is running'
    }

    render json: health_status, status: :ok
  end

  # Optional: Add a separate detailed health endpoint for monitoring
  def detailed
    health_status = {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      checks: {
        database: check_database,
        redis: check_redis
      }
    }

    overall_status = health_status[:checks].values.all? { |check| check[:status] == 'healthy' }
    status_code = overall_status ? :ok : :service_unavailable

    render json: health_status, status: status_code
  end

  private

  def check_database
    start_time = Time.current
    ActiveRecord::Base.connection.execute('SELECT 1')
    latency_ms = ((Time.current - start_time) * 1000).round

    {
      status: 'healthy',
      latency_ms: latency_ms
    }
  rescue => e
    {
      status: 'unhealthy',
      error: e.message
    }
  end

  def check_redis
    start_time = Time.current
    Redis.new(url: ENV['REDIS_URL']).ping
    latency_ms = ((Time.current - start_time) * 1000).round

    {
      status: 'healthy',
      latency_ms: latency_ms
    }
  rescue => e
    {
      status: 'unhealthy',
      error: e.message
    }
  end
end
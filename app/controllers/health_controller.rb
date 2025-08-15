class HealthController < ApplicationController
  skip_before_action :authenticate_user!, if: :health_check_request?
  skip_before_action :verify_authenticity_token

  def show
    health_status = {
      status: 'ok',
      timestamp: Time.current.iso8601,
      rails: Rails.version,
      ruby: RUBY_VERSION,
      database: database_health,
      sidekiq: sidekiq_health,
      cache: cache_health
    }

    render json: health_status, status: :ok
  rescue StandardError => e
    render json: { status: 'error', message: e.message }, status: :service_unavailable
  end

  private

  def health_check_request?
    action_name == 'show'
  end

  def database_health
    ActiveRecord::Base.connection.execute('SELECT 1')
    'connected'
  rescue StandardError
    'disconnected'
  end

  def sidekiq_health
    if defined?(Sidekiq)
      stats = Sidekiq::Stats.new
      {
        processed: stats.processed,
        failed: stats.failed,
        queues: stats.queues.size,
        workers: stats.workers_size
      }
    else
      'not configured'
    end
  rescue StandardError
    'unavailable'
  end

  def cache_health
    Rails.cache.write('health_check', Time.current.to_i, expires_in: 10.seconds)
    Rails.cache.read('health_check') ? 'working' : 'failed'
  rescue StandardError
    'unavailable'
  end
end
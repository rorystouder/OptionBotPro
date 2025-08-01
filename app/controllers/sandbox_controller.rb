class SandboxController < ApplicationController
  def index
    @recent_tests = SandboxTestResult.order(created_at: :desc).limit(10)
    @environment_info = {
      rails_env: Rails.env,
      api_url: ENV["TASTYTRADE_API_URL"],
      sandbox_mode: Rails.application.config.respond_to?(:sandbox_mode) ? Rails.application.config.sandbox_mode : false,
      mock_data: Rails.application.config.respond_to?(:mock_market_data) ? Rails.application.config.mock_market_data : false
    }
  end

  def run_tests
    if Rails.env.production?
      redirect_to sandbox_path, alert: "Sandbox testing is not available in production environment."
      return
    end

    # Run tests in background job
    SandboxTestJob.perform_later(current_user.id)
    redirect_to sandbox_path, notice: "Sandbox tests initiated. Results will appear shortly."
  end

  def show
    @test_result = SandboxTestResult.find(params[:id])
    @test_data = JSON.parse(@test_result.test_data)
  rescue ActiveRecord::RecordNotFound
    redirect_to sandbox_path, alert: "Test result not found."
  end

  def environment_check
    render json: {
      environment: Rails.env,
      sandbox_mode: Rails.application.config.respond_to?(:sandbox_mode) ? Rails.application.config.sandbox_mode : false,
      api_url: ENV["TASTYTRADE_API_URL"],
      websocket_url: ENV["TASTYTRADE_WEBSOCKET_URL"],
      database: Rails.configuration.database_configuration[Rails.env]&.dig("database"),
      redis_url: ENV["REDIS_URL"],
      auto_execute: ENV["AUTO_EXECUTE_TRADES"],
      mock_data: ENV["MOCK_MARKET_DATA"]
    }
  end
end

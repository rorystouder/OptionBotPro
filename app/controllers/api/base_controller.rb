class Api::BaseController < ActionController::API
  before_action :authenticate_user_from_token
  
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
  rescue_from Tastytrade::AuthService::TokenExpiredError, with: :handle_token_expired
  rescue_from Tastytrade::ApiService::ApiError, with: :handle_api_error
  
  private
  
  def authenticate_user_from_token
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token.blank?
      render json: { error: 'Authorization token required' }, status: :unauthorized
      return
    end
    
    begin
      # Simple token-based authentication for API
      # In production, you'd want proper JWT or similar
      user_id = Rails.cache.read("api_token_#{token}")
      @current_user = User.find(user_id) if user_id
      
      unless @current_user
        render json: { error: 'Invalid or expired token' }, status: :unauthorized
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'User not found' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
  
  def render_success(data = nil, message = nil, status = :ok)
    response = { success: true }
    response[:message] = message if message
    response[:data] = data if data
    
    render json: response, status: status
  end
  
  def render_error(message, status = :bad_request, details = nil)
    response = { 
      success: false, 
      error: message 
    }
    response[:details] = details if details
    
    render json: response, status: status
  end
  
  def handle_standard_error(exception)
    Rails.logger.error "API Error: #{exception.class.name} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    render_error('An unexpected error occurred', :internal_server_error)
  end
  
  def handle_not_found(exception)
    render_error('Resource not found', :not_found)
  end
  
  def handle_validation_error(exception)
    render_error('Validation failed', :unprocessable_entity, exception.record.errors.full_messages)
  end
  
  def handle_token_expired(exception)
    render_error('TastyTrade authentication expired. Please re-authenticate.', :unauthorized)
  end
  
  def handle_api_error(exception)
    render_error("TastyTrade API error: #{exception.message}", :bad_gateway)
  end
end
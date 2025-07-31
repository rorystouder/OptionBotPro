class SessionsController < ApplicationController
  skip_before_action :authenticate_user, only: [:new, :create]
  
  def new
    if logged_in?
      redirect_to dashboard_path
    end
  end
  
  def create
    user = User.find_by(email: params[:email])
    
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      
      # Authenticate with TastyTrade API using stored credentials
      begin
        auth_service = Tastytrade::AuthService.new
        auth_service.authenticate(
          username: user.tastytrade_username,
          password: user.tastytrade_password
        )
        
        flash[:notice] = 'Successfully logged in and authenticated with TastyTrade'
      rescue Tastytrade::AuthService::AuthenticationError => e
        flash[:alert] = "TastyTrade authentication failed: #{e.message}"
      rescue => e
        Rails.logger.error "Unexpected TastyTrade auth error: #{e.message}"
        flash[:alert] = "TastyTrade authentication failed"
      end
      
      redirect_to dashboard_path
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    if current_user
      # Logout from TastyTrade API
      begin
        auth_service = Tastytrade::AuthService.new
        auth_service.logout(current_user.tastytrade_username)
      rescue => e
        Rails.logger.warn "Failed to logout from TastyTrade: #{e.message}"
      end
    end
    
    session[:user_id] = nil
    redirect_to login_path, notice: 'Logged out successfully'
  end
end
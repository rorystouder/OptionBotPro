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
      
      # Authenticate with TastyTrade API
      if params[:tastytrade_username].present? && params[:tastytrade_password].present?
        begin
          auth_service = Tastytrade::AuthService.new
          auth_service.authenticate(
            username: params[:tastytrade_username],
            password: params[:tastytrade_password]
          )
          
          flash[:notice] = 'Successfully logged in and authenticated with TastyTrade'
        rescue Tastytrade::AuthService::AuthenticationError => e
          flash[:alert] = "TastyTrade authentication failed: #{e.message}"
        end
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
        auth_service.logout(current_user.email)
      rescue => e
        Rails.logger.warn "Failed to logout from TastyTrade: #{e.message}"
      end
    end
    
    session[:user_id] = nil
    redirect_to login_path, notice: 'Logged out successfully'
  end
end
class SessionsController < ApplicationController
  skip_before_action :authenticate_user, only: [ :new, :create ]
  skip_before_action :verify_authenticity_token, only: [ :browser_close_logout ]

  def new
    if logged_in?
      redirect_to dashboard_path
    end
  end

  def create
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      # Check if password reset is required
      if user.password_reset_required?
        session[:pending_user_id] = user.id
        redirect_to change_password_path, alert: "You must change your password before continuing."
        return
      end

      session[:user_id] = user.id

      # Allow bypassing MFA in development
      if Rails.env.development? && params[:skip_mfa] == "true"
        session[:mfa_verified] = true
        redirect_to dashboard_path, notice: "Logged in successfully (MFA bypassed)" and return
      end

      # Check if MFA is enabled
      if user.mfa_enabled?
        session[:mfa_verified] = false
        session[:pending_redirect] = dashboard_path
        redirect_to mfa_verify_path, notice: "Please enter your MFA code to complete login."
        return
      else
        # Don't force MFA setup, just log them in
        session[:mfa_verified] = true
        redirect_to dashboard_path, notice: "Logged in successfully"
        return
      end

      # Authenticate with TastyTrade API using stored credentials
      begin
        auth_service = Tastytrade::AuthService.new
        auth_service.authenticate(
          username: user.tastytrade_username,
          password: user.tastytrade_password
        )

        flash[:notice] = "Successfully logged in and authenticated with TastyTrade"
      rescue Tastytrade::AuthService::AuthenticationError => e
        flash[:alert] = "TastyTrade authentication failed: #{e.message}"
      rescue => e
        Rails.logger.error "Unexpected TastyTrade auth error: #{e.message}"
        flash[:alert] = "TastyTrade authentication failed"
      end

      redirect_to dashboard_path
    else
      flash.now[:alert] = "Invalid email or password"
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
    redirect_to login_path, notice: "Logged out successfully"
  end

  def browser_close_logout
    if current_user
      # Logout from TastyTrade API
      begin
        auth_service = Tastytrade::AuthService.new
        auth_service.logout(current_user.tastytrade_username)
      rescue => e
        Rails.logger.warn "Failed to logout from TastyTrade during browser close: #{e.message}"
      end
    end

    # Clear session
    session[:user_id] = nil
    session[:mfa_verified] = nil
    session[:pending_redirect] = nil
    
    # Return minimal response for browser close
    head :ok
  end
end

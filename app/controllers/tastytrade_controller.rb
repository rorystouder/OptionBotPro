class TastytradeController < ApplicationController
  before_action :require_mfa_verification

  def connect_form
    # Show form to enter TastyTrade credentials
  end

  def connect
    username = params[:tastytrade_username]
    password = params[:tastytrade_password]
    
    if username.blank? || password.blank?
      flash[:alert] = "Please enter both username and password"
      render :connect_form
      return
    end

    # Test the credentials by attempting authentication
    begin
      auth_service = Tastytrade::AuthService.new
      result = auth_service.authenticate(username: username, password: password)
      
      # If we get here without an exception, authentication succeeded
      # Store encrypted credentials
      current_user.tastytrade_username = username
      current_user.tastytrade_password = password
      current_user.save!
      
      flash[:notice] = "Successfully connected to TastyTrade!"
      redirect_to dashboard_path
    rescue Tastytrade::AuthenticationError => e
      Rails.logger.error "TastyTrade authentication failed: #{e.message}"
      flash[:alert] = "Authentication failed. Please check your username and password."
      render :connect_form
    rescue => e
      Rails.logger.error "TastyTrade connection error: #{e.message}"
      flash[:alert] = "Connection failed. Please try again later."
      render :connect_form
    end
  end

  def disconnect
    # Clear TastyTrade credentials
    current_user.update!(
      encrypted_tastytrade_username: nil,
      encrypted_tastytrade_password: nil,
      tastytrade_credentials_iv: nil
    )
    
    # Clear any cached tokens
    if current_user.tastytrade_username
      Rails.cache.delete("tastytrade_token_#{current_user.tastytrade_username}")
    end
    
    flash[:notice] = "Disconnected from TastyTrade"
    redirect_to dashboard_path
  end

  private

  def require_mfa_verification
    unless logged_in?
      redirect_to login_path, alert: "Please log in to access TastyTrade settings."
      return
    end

    if current_user.mfa_enabled? && !session[:mfa_verified]
      session[:pending_redirect] = request.fullpath
      redirect_to mfa_verify_path, alert: "Please verify your identity with MFA."
    end
  end
end
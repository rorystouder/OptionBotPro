class TastytradeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:oauth_callback]
  
  include HTTParty

  def connect_form
    # Show form to enter TastyTrade credentials
  end
  
  def oauth_setup
    Rails.logger.info "[OAUTH] oauth_setup called - current_user: #{current_user&.email}"
    Rails.logger.info "[OAUTH] session[:user_id]: #{session[:user_id]}"
    Rails.logger.info "[OAUTH] session[:mfa_verified]: #{session[:mfa_verified]}"
    # Show OAuth configuration form
  end
  
  def oauth_save
    Rails.logger.info "[OAUTH] oauth_save called - current_user: #{current_user&.email}"
    Rails.logger.info "[OAUTH] Params: client_id=#{params[:client_id]}, environment=#{params[:environment]}"
    
    # Store OAuth credentials in session temporarily
    session[:tastytrade_client_id] = params[:client_id]
    session[:tastytrade_client_secret] = params[:client_secret]
    session[:tastytrade_env] = params[:environment]
    
    # Set API URL and OAuth URLs based on environment
    if params[:environment] == 'sandbox'
      session[:tastytrade_api_url] = 'https://api.cert.tastyworks.com'
      session[:tastytrade_oauth_auth_url] = 'https://cert-my.staging-tasty.works/auth.html'
    else
      session[:tastytrade_api_url] = 'https://api.tastyworks.com'
      session[:tastytrade_oauth_auth_url] = 'https://my.tastytrade.com/auth.html'
    end
    
    # Store in environment for this request
    ENV['TASTYTRADE_CLIENT_ID'] = params[:client_id]
    ENV['TASTYTRADE_CLIENT_SECRET'] = params[:client_secret]
    ENV['TASTYTRADE_ENV'] = params[:environment]
    ENV['TASTYTRADE_API_URL'] = session[:tastytrade_api_url]
    
    flash[:notice] = "OAuth credentials saved. Redirecting to TastyTrade for authorization..."
    
    # Redirect to OAuth authorization
    redirect_to tastytrade_oauth_authorize_path
  end
  
  def oauth_authorize
    # TastyTrade uses OAuth 2.0 authorization code flow, not client credentials
    client_id = session[:tastytrade_client_id] || ENV['TASTYTRADE_CLIENT_ID']
    client_secret = session[:tastytrade_client_secret] || ENV['TASTYTRADE_CLIENT_SECRET']
    
    Rails.logger.info "[OAUTH] Starting OAuth authorization code flow with client_id: #{client_id}"
    
    # Generate OAuth state for security
    oauth_state = SecureRandom.hex(32)
    session[:oauth_state] = oauth_state
    
    # Validate required credentials
    if client_id.blank? || client_secret.blank?
      flash[:alert] = "OAuth Client ID and Secret are required. Please configure them first."
      redirect_to tastytrade_oauth_setup_path
      return
    end
    
    # Build redirect URI
    redirect_uri = url_for(controller: 'tastytrade', action: 'oauth_callback', only_path: false)
    
    # Use correct OAuth auth URL based on environment
    oauth_auth_url = session[:tastytrade_oauth_auth_url] || 'https://my.tastytrade.com/auth.html'
    
    # Redirect to TastyTrade authorization page (authorization code flow)
    authorization_url = "#{oauth_auth_url}?" +
                       "response_type=code&" +
                       "client_id=#{CGI.escape(client_id)}&" +
                       "redirect_uri=#{CGI.escape(redirect_uri)}&" +
                       "scope=#{CGI.escape('read trade openid')}&" +
                       "state=#{CGI.escape(oauth_state)}"
    
    Rails.logger.info "[OAUTH] Redirect URI: #{redirect_uri}"
    Rails.logger.info "[OAUTH] Redirecting to authorization URL: #{authorization_url}"
    
    flash[:notice] = "Redirecting to TastyTrade for authorization. If you get '404 Client not found', your OAuth client needs to be registered with TastyTrade first."
    redirect_to authorization_url, allow_other_host: true
  end
  
  def oauth_callback
    Rails.logger.info "[OAUTH] OAuth callback received with params: #{params.inspect}"
    
    # Handle OAuth callback from TastyTrade
    if params[:state] != session[:oauth_state]
      Rails.logger.error "[OAUTH] Invalid OAuth state. Expected: #{session[:oauth_state]}, Got: #{params[:state]}"
      flash[:alert] = "Invalid OAuth state. Please try again."
      redirect_to dashboard_path
      return
    end
    
    if params[:error]
      Rails.logger.error "[OAUTH] OAuth authorization failed: #{params[:error]} - #{params[:error_description]}"
      flash[:alert] = "OAuth authorization failed: #{params[:error_description]}"
      redirect_to dashboard_path
      return
    end
    
    unless params[:code]
      Rails.logger.error "[OAUTH] No authorization code received"
      flash[:alert] = "No authorization code received"
      redirect_to dashboard_path
      return
    end
    
    # Exchange authorization code for access token
    begin
      client_id = session[:tastytrade_client_id] || ENV['TASTYTRADE_CLIENT_ID']
      client_secret = session[:tastytrade_client_secret] || ENV['TASTYTRADE_CLIENT_SECRET']
      redirect_uri = url_for(controller: 'tastytrade', action: 'oauth_callback', only_path: false)
      
      Rails.logger.info "[OAUTH] Exchanging authorization code for tokens"
      
      token_response = HTTParty.post("#{session[:tastytrade_api_url] || ENV['TASTYTRADE_API_URL']}/oauth/token", {
        body: {
          grant_type: "authorization_code",
          code: params[:code],
          redirect_uri: redirect_uri,
          client_id: client_id,
          client_secret: client_secret
        }.to_json,
        headers: { 
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      })
      
      Rails.logger.info "[OAUTH] Token exchange response code: #{token_response.code}"
      Rails.logger.info "[OAUTH] Token exchange response body: #{token_response.body}"
      
      if token_response.code == 200
        data = token_response.parsed_response
        access_token = data["access_token"]
        refresh_token = data["refresh_token"]
        expires_in = data["expires_in"] || 900 # Default 15 minutes
        
        if access_token
          # Store the OAuth tokens
          current_user.tastytrade_oauth_token = access_token
          current_user.tastytrade_oauth_refresh_token = refresh_token if refresh_token
          current_user.tastytrade_oauth_expires_at = Time.current + expires_in.seconds
          current_user.save!
          
          Rails.logger.info "[OAUTH] Successfully stored OAuth tokens"
          flash[:notice] = "Successfully connected to TastyTrade via OAuth!"
          redirect_to dashboard_path
        else
          Rails.logger.error "[OAUTH] No access token in response: #{data.inspect}"
          flash[:alert] = "No access token received from TastyTrade"
          redirect_to dashboard_path
        end
      else
        Rails.logger.error "[OAUTH] Token exchange failed: #{token_response.body}"
        error_message = token_response.parsed_response&.dig('error_description') || 
                       token_response.parsed_response&.dig('error') || 
                       'Token exchange failed'
        flash[:alert] = "OAuth token exchange failed: #{error_message}"
        redirect_to dashboard_path
      end
      
    rescue => e
      Rails.logger.error "[OAUTH] Token exchange error: #{e.message}"
      flash[:alert] = "OAuth token exchange failed: #{e.message}"
      redirect_to dashboard_path
    end
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
end
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Protect from CSRF attacks
  protect_from_forgery with: :exception
  
  include ActionView::Helpers::NumberHelper
  
  before_action :authenticate_user
  before_action :require_mfa_verification
  before_action :set_current_user
  
  private
  
  def authenticate_user
    unless logged_in?
      redirect_to login_path, alert: 'Please log in to continue'
    end
  end
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def logged_in?
    !!current_user
  end
  
  def require_mfa_verification
    return unless logged_in? && current_user.mfa_enabled?
    
    # Skip MFA check for certain controllers/actions
    return if skip_mfa_verification?
    
    unless session[:mfa_verified]
      session[:pending_redirect] = request.fullpath
      redirect_to mfa_verify_path, alert: 'Please complete MFA verification to continue.'
    end
  end
  
  def skip_mfa_verification?
    # Skip MFA for these controllers/actions
    mfa_exempt_controllers = %w[sessions mfa users password_resets]
    mfa_exempt_actions = %w[new create verify verify_form setup enable disable]
    
    controller_name.in?(mfa_exempt_controllers) || 
    action_name.in?(mfa_exempt_actions) ||
    (controller_name == 'users' && action_name.in?(%w[new create change_password update_password]))
  end

  def set_current_user
    Current.user = current_user
  end
  
  helper_method :current_user, :logged_in?
end

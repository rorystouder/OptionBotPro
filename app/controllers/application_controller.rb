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
    Rails.logger.info "[AUTH] authenticate_user called for #{controller_name}##{action_name}"
    Rails.logger.info "[AUTH] session[:user_id]: #{session[:user_id]}"
    Rails.logger.info "[AUTH] logged_in?: #{logged_in?}"
    
    unless logged_in?
      Rails.logger.warn "[AUTH] User not logged in, redirecting to login"
      redirect_to login_path, alert: "Please log in to continue"
    else
      Rails.logger.info "[AUTH] User authenticated: #{current_user.email}"
    end
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_mfa_verification
    Rails.logger.info "[MFA] require_mfa_verification called for #{controller_name}##{action_name}"
    Rails.logger.info "[MFA] logged_in?: #{logged_in?}"
    Rails.logger.info "[MFA] current_user.mfa_enabled?: #{logged_in? && current_user&.mfa_enabled?}"
    Rails.logger.info "[MFA] skip_mfa_verification?: #{skip_mfa_verification?}"
    Rails.logger.info "[MFA] session[:mfa_verified]: #{session[:mfa_verified]}"
    
    return unless logged_in? && current_user.mfa_enabled?

    # Skip MFA check for certain controllers/actions
    if skip_mfa_verification?
      Rails.logger.info "[MFA] Skipping MFA verification"
      return
    end

    unless session[:mfa_verified]
      Rails.logger.warn "[MFA] MFA verification required, redirecting"
      session[:pending_redirect] = request.fullpath
      redirect_to mfa_verify_path, alert: "Please complete MFA verification to continue."
    else
      Rails.logger.info "[MFA] MFA verification passed"
    end
  end

  def skip_mfa_verification?
    # Skip MFA for these controllers/actions
    mfa_exempt_controllers = %w[sessions mfa users password_resets tastytrade]
    mfa_exempt_actions = %w[new create verify verify_form setup enable disable oauth_setup oauth_save oauth_authorize oauth_callback]

    exempt = controller_name.in?(mfa_exempt_controllers) ||
             action_name.in?(mfa_exempt_actions) ||
             (controller_name == "users" && action_name.in?(%w[new create change_password update_password]))
    
    Rails.logger.info "[MFA] Skip check - controller: #{controller_name}, action: #{action_name}, exempt: #{exempt}"
    exempt
  end

  def set_current_user
    Current.user = current_user
  end

  helper_method :current_user, :logged_in?
end

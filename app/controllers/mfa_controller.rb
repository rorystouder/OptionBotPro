class MfaController < ApplicationController
  before_action :require_login
  before_action :require_mfa_setup, only: [ :verify ]

  def setup
    if current_user.mfa_enabled?
      redirect_to mfa_status_path, notice: "MFA is already enabled for your account."
      return
    end

    # Generate new MFA secret for setup
    current_user.mfa_secret = ROTP::Base32.random
    current_user.save!

    @qr_code = current_user.mfa_qr_code
    @manual_key = current_user.mfa_secret
  end

  def enable
    if current_user.mfa_enabled?
      redirect_to mfa_status_path, alert: "MFA is already enabled."
      return
    end

    code = params[:verification_code]
    if current_user.verify_mfa_code(code)
      current_user.enable_mfa!
      session[:mfa_verified] = true

      # Redirect to originally requested page or dashboard
      redirect_path = session.delete(:pending_redirect) || dashboard_path
      redirect_to redirect_path, notice: "MFA has been successfully enabled! Your account is now secure."
    else
      redirect_to mfa_setup_path, alert: "Invalid verification code. Please try again."
    end
  end

  def disable
    unless current_user.mfa_enabled?
      redirect_to mfa_status_path, alert: "MFA is not enabled."
      return
    end

    # Require password confirmation for disabling MFA
    unless current_user.authenticate(params[:password])
      redirect_to mfa_status_path, alert: "Incorrect password. Cannot disable MFA."
      return
    end

    current_user.disable_mfa!
    session[:mfa_verified] = nil

    redirect_to mfa_status_path, notice: "MFA has been disabled. We recommend enabling it again for security."
  end

  def status
    @backup_codes = current_user.backup_codes_array if current_user.mfa_enabled?
  end

  def verify
    # This is called during login process for MFA verification
    code = params[:mfa_code]

    if current_user.verify_mfa_code(code)
      session[:mfa_verified] = true

      # Redirect to originally requested page or dashboard
      redirect_to session.delete(:pending_redirect) || dashboard_path,
                  notice: "MFA verification successful."
    else
      @error = "Invalid verification code. Please try again."
      render :verify_form
    end
  end

  def verify_form
    # Show MFA verification form during login
  end

  def regenerate_backup_codes
    unless current_user.mfa_enabled?
      redirect_to mfa_status_path, alert: "MFA must be enabled to generate backup codes."
      return
    end

    # Require password confirmation
    unless current_user.authenticate(params[:password])
      redirect_to mfa_status_path, alert: "Incorrect password. Cannot regenerate backup codes."
      return
    end

    current_user.mfa_backup_codes = current_user.generate_backup_codes
    current_user.save!

    redirect_to mfa_status_path, notice: "New backup codes generated. Please save them securely."
  end

  private

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Please log in to access MFA settings."
    end
  end

  def require_mfa_setup
    unless current_user.mfa_enabled?
      redirect_to mfa_setup_path, alert: "Please set up MFA first."
    end
  end
end

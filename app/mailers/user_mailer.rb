class UserMailer < ApplicationMailer
  default from: 'OptionBotPro Support <noreply@optionbotpro.com>'

  def password_reset(user, temporary_password)
    @user = user
    @temporary_password = temporary_password
    @login_url = login_url
    
    mail(
      to: @user.email,
      subject: 'OptionBotPro - Password Reset - Action Required'
    )
  end

  def mfa_enabled(user)
    @user = user
    @login_url = login_url
    
    mail(
      to: @user.email,
      subject: 'OptionBotPro - Multi-Factor Authentication Enabled'
    )
  end

  def mfa_disabled(user)
    @user = user
    @mfa_setup_url = mfa_setup_url
    
    mail(
      to: @user.email,
      subject: 'OptionBotPro - Multi-Factor Authentication Disabled - Security Alert'
    )
  end

  def security_alert(user, action, ip_address = nil)
    @user = user
    @action = action
    @ip_address = ip_address
    @timestamp = Time.current
    @settings_url = user_url
    
    mail(
      to: @user.email,
      subject: "OptionBotPro - Security Alert: #{action}"
    )
  end
end
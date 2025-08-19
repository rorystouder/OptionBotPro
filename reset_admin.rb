#!/usr/bin/env ruby
# Script to reset admin account

require_relative 'config/environment'

user = User.find_by(email: 'admin@optionbotpro.com')

if user
  # Reset password
  user.password = 'admin123'
  user.password_confirmation = 'admin123'

  # Disable MFA
  user.mfa_enabled = false
  user.mfa_secret = nil
  user.mfa_backup_codes = nil

  # Clear any password reset requirements
  user.password_reset_required = false
  user.password_reset_token = nil
  user.password_reset_sent_at = nil

  user.save!

  puts "✅ Admin account reset successfully!"
  puts "   Email: admin@optionbotpro.com"
  puts "   Password: admin123"
  puts "   MFA: Disabled"
  puts ""
  puts "You can now login at http://localhost:3000/login"
  puts "To bypass MFA in development, add ?skip_mfa=true to the login form"
else
  puts "❌ Admin user not found!"
end

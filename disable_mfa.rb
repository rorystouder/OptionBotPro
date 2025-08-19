#!/usr/bin/env ruby
# Script to disable MFA for admin account

require_relative 'config/environment'

user = User.find(1)
user.mfa_enabled = false
user.mfa_secret = nil
user.mfa_backup_codes = nil
user.save!

puts "MFA disabled for #{user.email}"
puts "You can now login without MFA"

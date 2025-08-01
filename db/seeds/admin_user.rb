# Create Admin User for OptionBotPro

puts "Creating admin user..."

admin_email = "admin@optionbotpro.com"
admin_password = "AdminPassword123!"

admin_user = User.find_or_create_by(email: admin_email) do |user|
  user.first_name = "Admin"
  user.last_name = "User"
  user.password = admin_password
  user.password_confirmation = admin_password
  user.admin = true
  user.active = true
end

# Set dummy TastyTrade credentials for admin after user is saved (needed for encryption key)
if admin_user.persisted? && (admin_user.tastytrade_username.nil? rescue true)
  admin_user.tastytrade_username = admin_email
  admin_user.tastytrade_password = "dummy_password"
  admin_user.save!
end

# Ensure admin status is set
if admin_user.persisted? && !admin_user.admin?
  admin_user.update!(admin: true)
end

puts "Admin user created/updated:"
puts "  Email: #{admin_user.email}"
puts "  Admin: #{admin_user.admin?}"
puts ""
puts "🔐 Admin Login Credentials:"
puts "  Email: #{admin_email}"
puts "  Password: #{admin_password}"
puts ""
puts "🚀 Access admin panel at: /admin"
puts "Done!"

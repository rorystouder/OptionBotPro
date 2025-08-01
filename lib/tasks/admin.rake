require "io/console"

namespace :admin do
  desc "Update admin user password securely"
  task update_password: :environment do
    print "Enter new admin password: "
    new_password = STDIN.noecho(&:gets).chomp
    puts ""

    print "Confirm new admin password: "
    confirmation = STDIN.noecho(&:gets).chomp
    puts ""

    if new_password != confirmation
      puts "❌ Passwords don't match!"
      exit 1
    end

    if new_password.length < 8
      puts "❌ Password must be at least 8 characters long!"
      exit 1
    end

    admin_user = User.find_by(email: "admin@optionbotpro.com")

    if admin_user.nil?
      puts "❌ Admin user not found!"
      exit 1
    end

    admin_user.password = new_password
    admin_user.password_confirmation = new_password

    if admin_user.save
      puts "✅ Admin password updated successfully!"
      puts "🔐 You can now log in with your new password at /login"
    else
      puts "❌ Failed to update password:"
      admin_user.errors.full_messages.each do |error|
        puts "   - #{error}"
      end
      exit 1
    end
  end

  desc "Create or reset admin user with secure password"
  task create_secure: :environment do
    print "Enter email for admin user (default: admin@optionbotpro.com): "
    email = STDIN.gets.chomp
    email = "admin@optionbotpro.com" if email.blank?

    print "Enter password for admin user: "
    password = STDIN.noecho(&:gets).chomp
    puts ""

    print "Confirm password: "
    confirmation = STDIN.noecho(&:gets).chomp
    puts ""

    if password != confirmation
      puts "❌ Passwords don't match!"
      exit 1
    end

    if password.length < 8
      puts "❌ Password must be at least 8 characters long!"
      exit 1
    end

    admin_user = User.find_or_initialize_by(email: email)
    admin_user.first_name = "Admin"
    admin_user.last_name = "User"
    admin_user.password = password
    admin_user.password_confirmation = password
    admin_user.admin = true
    admin_user.active = true

    if admin_user.save
      # Set dummy TastyTrade credentials after user is saved
      admin_user.tastytrade_username = email
      admin_user.tastytrade_password = "dummy_password"
      admin_user.save!

      puts "✅ Admin user created/updated successfully!"
      puts "📧 Email: #{email}"
      puts "🔐 Password: [hidden]"
      puts "🚀 Access admin panel at: /admin"
    else
      puts "❌ Failed to create/update admin user:"
      admin_user.errors.full_messages.each do |error|
        puts "   - #{error}"
      end
      exit 1
    end
  end

  desc "Show admin user info"
  task info: :environment do
    admin_user = User.find_by(email: "admin@optionbotpro.com")

    if admin_user
      puts "👤 Admin User Information:"
      puts "   Email: #{admin_user.email}"
      puts "   Name: #{admin_user.full_name}"
      puts "   Admin: #{admin_user.admin? ? '✅' : '❌'}"
      puts "   Active: #{admin_user.active? ? '✅' : '❌'}"
      puts "   Created: #{admin_user.created_at}"
      puts "   Last Updated: #{admin_user.updated_at}"
    else
      puts "❌ Admin user not found!"
      puts "💡 Run 'rails admin:create_secure' to create an admin user"
    end
  end
end

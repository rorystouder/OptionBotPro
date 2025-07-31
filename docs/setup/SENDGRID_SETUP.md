# SendGrid Email Setup Guide for OptionBotPro

This guide explains how to set up SendGrid for sending transactional emails in OptionBotPro, including password reset notifications, MFA alerts, and security notifications.

## Why SendGrid?

SendGrid is chosen for OptionBotPro because:
- **Reliability**: 99.9% uptime SLA for critical trading notifications
- **Deliverability**: High inbox placement rates for security emails
- **Compliance**: SOC 2 Type II certified, suitable for financial applications
- **Scale**: Handles up to 100 emails/day on free tier, 40K+ on paid plans
- **Security**: Built-in spam protection and authentication

## Current Email Implementation

OptionBotPro is configured to send these email types:
- **Password Reset Emails** - When admin resets user passwords
- **MFA Notifications** - When MFA is enabled/disabled
- **Security Alerts** - For suspicious account activity
- **System Notifications** - For trading alerts and updates

## Setup Instructions

### Step 1: Create SendGrid Account

1. **Sign up for SendGrid**
   - Go to: https://sendgrid.com/
   - Click "Get Started for Free"
   - Choose "Essentials" plan (free tier: 100 emails/day)

2. **Verify your account**
   - Complete email verification
   - Set up two-factor authentication (recommended for financial apps)

### Step 2: Create API Key

1. **Navigate to API Keys**
   - Login to SendGrid dashboard
   - Go to Settings → API Keys
   - Click "Create API Key"

2. **Configure API Key**
   - **Name**: `OptionBotPro-Production` (or `OptionBotPro-Dev`)
   - **Permissions**: Choose "Full Access" (or "Restricted Access" with Mail Send permissions)
   - **Click "Create & View"**
   - **Copy the API key** (you won't see it again!)

### Step 3: Configure Domain Authentication (Recommended)

1. **Set up Domain Authentication**
   - Go to Settings → Sender Authentication → Domain Authentication
   - Click "Authenticate Your Domain"
   - Enter your domain: `optionbotpro.com`
   - Follow DNS setup instructions

2. **Verify DNS Records**
   - Add the provided CNAME records to your DNS
   - Wait for verification (can take up to 48 hours)
   - Verified domains have higher deliverability

### Step 4: Add API Key to OptionBotPro

1. **Update Environment Variables**
   
   **For Development:**
   ```bash
   # Add to .env.development or .env file
   SENDGRID_API_KEY=SG.your-api-key-here
   ```

   **For Production:**
   ```bash
   # Add to production environment variables
   export SENDGRID_API_KEY=SG.your-production-api-key-here
   ```

2. **Verify Configuration**
   ```bash
   # Test email sending in Rails console
   rails console
   UserMailer.password_reset(User.first, "temp123!").deliver_now
   ```

### Step 5: Configure Sender Identity

1. **Set up Sender Identity**
   - Go to Settings → Sender Authentication → Single Sender Verification
   - Add: `noreply@optionbotpro.com`
   - Verify the email address

2. **Update Application Settings**
   ```ruby
   # In config/application.rb or mailer
   config.action_mailer.default_options = {
     from: 'OptionBotPro Security <noreply@optionbotpro.com>'
   }
   ```

## Email Templates

OptionBotPro includes pre-built email templates:

### Password Reset Email
- **Template**: `app/views/user_mailer/password_reset.html.erb`
- **Features**: Secure temporary password delivery, security warnings
- **Trigger**: When admin resets user password

### MFA Notification Emails
- **Templates**: `mfa_enabled.html.erb`, `mfa_disabled.html.erb`
- **Features**: Security alerts for MFA changes
- **Trigger**: When users enable/disable MFA

### Security Alert Emails
- **Template**: `security_alert.html.erb`
- **Features**: Suspicious activity notifications
- **Trigger**: Failed login attempts, unusual access patterns

## Production Configuration

### Environment-Specific Settings

**Development (`config/environments/development.rb`):**
```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.sendgrid.net',
  port: 587,
  domain: 'optionbotpro.com',
  user_name: 'apikey',
  password: ENV['SENDGRID_API_KEY'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

**Production (`config/environments/production.rb`):**
```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.default_url_options = { 
  host: 'optionbotpro.com', 
  protocol: 'https' 
}
```

### Security Best Practices

1. **API Key Security**
   - Use environment variables, never commit keys to Git
   - Use different API keys for development/production
   - Rotate API keys quarterly

2. **Email Security**
   - Enable domain authentication (SPF, DKIM, DMARC)
   - Use HTTPS links in all emails
   - Include unsubscribe options where required

3. **Monitoring**
   - Monitor email bounce rates
   - Track delivery and open rates
   - Set up alerts for delivery failures

## Testing Email Delivery

### Development Testing
```bash
# In Rails console
rails console

# Test password reset email
user = User.first
UserMailer.password_reset(user, "TempPass123!").deliver_now

# Test MFA notification
UserMailer.mfa_enabled(user).deliver_now

# Check email was delivered
# Check SendGrid dashboard for delivery status
```

### Production Testing
1. Send test emails to different providers (Gmail, Outlook, Yahoo)
2. Check spam folders
3. Verify all links work correctly
4. Test on mobile devices

## Monitoring and Analytics

### SendGrid Dashboard
- **Activity Feed**: Real-time email delivery status
- **Statistics**: Delivery rates, bounces, spam reports
- **Suppressions**: Manage bounced/blocked emails

### Key Metrics to Monitor
- **Delivery Rate**: Should be >95%
- **Bounce Rate**: Should be <5%
- **Spam Rate**: Should be <0.1%
- **Open Rate**: Varies by email type

## Troubleshooting

### Common Issues

#### 1. "Authentication failed" Error
```bash
# Check API key is correct
echo $SENDGRID_API_KEY

# Verify key has mail send permissions
# Check SendGrid dashboard → API Keys
```

#### 2. Emails Going to Spam
- Set up domain authentication
- Check sender reputation
- Review email content for spam triggers
- Use authenticated sender address

#### 3. High Bounce Rate
- Clean email list regularly
- Use double opt-in for signups
- Remove hard bounces immediately

#### 4. Production Emails Not Sending
```ruby
# Check production configuration
Rails.application.config.action_mailer.delivery_method
Rails.application.config.action_mailer.smtp_settings

# Test SMTP connection
require 'net/smtp'
Net::SMTP.start('smtp.sendgrid.net', 587, 'optionbotpro.com', 'apikey', ENV['SENDGRID_API_KEY'], :plain)
```

## Pricing and Limits

### Free Tier (Essentials)
- **100 emails/day**
- **2,000 contacts**
- **Basic support**
- **Perfect for development and small deployments**

### Paid Plans
- **Pro ($19.95/month)**: 40,000 emails/month
- **Premier ($99.95/month)**: 120,000 emails/month
- **Advanced features**: Dedicated IP, advanced analytics

## Integration with OptionBotPro Features

### Password Reset Flow
1. Admin clicks "Reset Password" in user management
2. System generates secure temporary password
3. Email sent via SendGrid with temp password
4. User receives email with login instructions
5. System forces password change on next login

### MFA Security Flow
1. User enables/disables MFA
2. Security notification sent via SendGrid
3. Admin receives alert for security changes
4. Audit trail maintained for compliance

### Trading Alerts (Future)
- Position limit warnings
- Risk management alerts
- Daily/weekly trading summaries
- Portfolio performance reports

## Compliance and Security

### Financial Industry Requirements
- **Data encryption**: All emails use TLS
- **Audit logging**: SendGrid provides delivery logs
- **Retention**: Email logs kept for compliance
- **Privacy**: GDPR and CCPA compliant

### Security Features
- **API key rotation**: Regular key updates
- **IP whitelisting**: Restrict API access
- **Webhook validation**: Secure event handling
- **Bounce handling**: Automatic suppression lists

---

**Last Updated**: July 31, 2025  
**Status**: Ready for SendGrid integration  
**Priority**: High - Required for production security features
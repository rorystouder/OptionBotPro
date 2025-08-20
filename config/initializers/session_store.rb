# Configure session to expire when browser closes
Rails.application.config.session_store :cookie_store,
  key: "_option_bot_pro_session",
  expire_after: nil, # Session cookie (expires when browser closes)
  secure: Rails.env.production?, # Only send over HTTPS in production
  httponly: true, # Prevent JavaScript access to session cookie
  same_site: :lax # CSRF protection

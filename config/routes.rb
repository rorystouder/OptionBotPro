Rails.application.routes.draw do
  namespace :admin do
    root "dashboard#index"
    resources :users, except: [ :new, :create ] do
      member do
        post :reset_password
      end
    end
    resources :subscription_tiers
    get "metrics", to: "dashboard#metrics"
    get "settings", to: "settings#show"
    patch "settings/password", to: "settings#update_password", as: :update_password

    # Database management routes
    get "database", to: "database#index"
    get "database/query", to: "database#query"
    post "database/query", to: "database#query"
    get "database/table/:table_name", to: "database#table", as: :database_table
    get "database/schema/:table_name", to: "database#schema", as: :database_schema
  end
  # Subscription routes
  get "pricing", to: "subscriptions#index", as: :pricing
  get "subscription", to: "subscriptions#show", as: :subscription
  post "subscribe/:tier_id", to: "subscriptions#create", as: :subscribe
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Health check endpoint for monitoring
  get "health" => "health#show", as: :health_check

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path - Landing page for public, dashboard for logged in users
  root "home#index"

  # Authentication routes
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  post "logout/browser_close", to: "sessions#browser_close_logout"

  get "signup", to: "users#new"
  post "signup", to: "users#create"

  # User profile routes
  get "profile", to: "users#show", as: :user
  get "profile/edit", to: "users#edit", as: :edit_user
  patch "profile", to: "users#update"

  # TastyTrade connection routes
  get "tastytrade/connect", to: "tastytrade#connect_form", as: :tastytrade_connect
  post "tastytrade/connect", to: "tastytrade#connect"
  delete "tastytrade/disconnect", to: "tastytrade#disconnect", as: :tastytrade_disconnect

  # TastyTrade OAuth routes
  get "tastytrade/oauth/setup", to: "tastytrade#oauth_setup", as: :tastytrade_oauth_setup
  post "tastytrade/oauth/save", to: "tastytrade#oauth_save", as: :tastytrade_oauth_save
  get "tastytrade/oauth/authorize", to: "tastytrade#oauth_authorize", as: :tastytrade_oauth_authorize
  get "tastytrade/oauth/callback", to: "tastytrade#oauth_callback", as: :tastytrade_oauth_callback

  # Password change routes (for forced password changes)
  get "change_password", to: "users#change_password"
  patch "change_password", to: "users#update_password"

  # MFA routes
  get "mfa/setup", to: "mfa#setup", as: :mfa_setup
  post "mfa/enable", to: "mfa#enable", as: :mfa_enable
  get "mfa/status", to: "mfa#status", as: :mfa_status
  delete "mfa/disable", to: "mfa#disable", as: :mfa_disable
  get "mfa/verify", to: "mfa#verify_form", as: :mfa_verify
  post "mfa/verify", to: "mfa#verify"
  post "mfa/regenerate_backup_codes", to: "mfa#regenerate_backup_codes", as: :mfa_regenerate_backup_codes

  # Dashboard
  get "dashboard", to: "dashboard#index"

  # Scanner routes
  get "scanner", to: "scanner#index"
  post "scanner/scan", to: "scanner#scan"
  get "scanner/:id", to: "scanner#show", as: :scanner_result

  # Sandbox testing routes
  get "sandbox", to: "sandbox#index"
  post "sandbox/run_tests", to: "sandbox#run_tests"
  get "sandbox/environment_check", to: "sandbox#environment_check"
  get "sandbox/:id", to: "sandbox#show", as: :sandbox_result

  # Legal routes
  get "terms", to: "legal#terms"
  get "privacy", to: "legal#privacy"
  get "risk_disclosure", to: "legal#risk_disclosure"

  # Debug routes (remove in production)
  get "auth_test/status", to: "auth_test#status"
  post "auth_test/clear_session", to: "auth_test#clear_session"

  # API routes
  namespace :api do
    namespace :v1 do
      resources :accounts, only: [ :index, :show ] do
        member do
          get :balances
        end
      end

      resources :positions, only: [ :index, :show ] do
        collection do
          get :sync
        end
      end

      resources :orders do
        member do
          patch :cancel
          patch :modify
        end
      end

      resources :options, only: [ :show ] do
        collection do
          get :quotes
        end
      end

      resources :portfolio_protections do
        member do
          post :emergency_stop
          delete :clear_emergency_stop
        end
        collection do
          get :status
          post :validate_trade
        end
      end

      get "market_data/quotes", to: "options#quotes"
      get "market_data/option_chain/:symbol", to: "options#show"
    end
  end
end

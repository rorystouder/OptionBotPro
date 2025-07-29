module Tastytrade
  class ApiService
    include HTTParty
    base_uri ENV.fetch('TASTYTRADE_API_URL', 'https://api.tastyworks.com')
    
    def initialize(user)
      @user = user
      @auth_service = Tastytrade::AuthService.new
    end
    
    # Account Methods
    def get_account(account_id)
      make_request(:get, "/accounts/#{account_id}")
    end
    
    def get_accounts
      make_request(:get, "/customers/#{@user.tastytrade_customer_id}/accounts")
    end
    
    def get_positions(account_id)
      make_request(:get, "/accounts/#{account_id}/positions")
    end
    
    def get_balances(account_id)
      make_request(:get, "/accounts/#{account_id}/balances")
    end
    
    # Market Data Methods
    def get_option_chain(symbol, expiration_date = nil)
      params = {}
      params[:expiration_date] = expiration_date if expiration_date
      
      make_request(:get, "/option-chains/#{symbol}/nested", params)
    end
    
    def get_quote(symbol)
      make_request(:get, "/marketdata/quotes", { symbols: symbol })
    end
    
    def get_quotes(symbols)
      make_request(:get, "/marketdata/quotes", { symbols: symbols.join(',') })
    end
    
    # Order Methods
    def place_order(account_id, order_params)
      body = build_order_body(order_params)
      make_request(:post, "/accounts/#{account_id}/orders", nil, body)
    end
    
    def get_order(account_id, order_id)
      make_request(:get, "/accounts/#{account_id}/orders/#{order_id}")
    end
    
    def get_orders(account_id, params = {})
      make_request(:get, "/accounts/#{account_id}/orders", params)
    end
    
    def cancel_order(account_id, order_id)
      make_request(:delete, "/accounts/#{account_id}/orders/#{order_id}")
    end
    
    def replace_order(account_id, order_id, modifications)
      body = build_order_modifications(modifications)
      make_request(:put, "/accounts/#{account_id}/orders/#{order_id}", nil, body)
    end
    
    private
    
    def make_request(method, path, params = nil, body = nil)
      options = {
        headers: @auth_service.authenticated_headers(@user.email).merge({
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        })
      }
      
      options[:query] = params if params
      options[:body] = body.to_json if body
      
      response = self.class.send(method, path, options)
      
      handle_response(response)
    rescue Tastytrade::AuthService::TokenExpiredError => e
      Rails.logger.warn "Token expired for user #{@user.email}: #{e.message}"
      raise TokenExpiredError, "Please re-authenticate"
    end
    
    def handle_response(response)
      case response.code
      when 200..299
        response.parsed_response
      when 401
        raise TokenExpiredError, "Authentication token expired"
      when 422
        raise ValidationError, parse_validation_errors(response)
      when 429
        raise RateLimitError, "Rate limit exceeded. Please try again later."
      else
        raise ApiError, "Request failed (#{response.code}): #{response.body}"
      end
    end
    
    def parse_validation_errors(response)
      errors = response.parsed_response.dig('error', 'errors') || []
      errors.map { |e| "#{e['field']}: #{e['message']}" }.join(', ')
    end
    
    def build_order_body(params)
      {
        type: params[:order_type],
        symbol: params[:symbol],
        quantity: params[:quantity],
        action: params[:action],
        price: params[:price],
        'time-in-force' => params[:time_in_force] || 'day',
        legs: params[:legs] # For multi-leg orders
      }.compact
    end
    
    def build_order_modifications(params)
      {
        type: params[:order_type],
        price: params[:price],
        quantity: params[:quantity],
        'time-in-force' => params[:time_in_force]
      }.compact
    end
    
    class ApiError < StandardError; end
    class TokenExpiredError < StandardError; end
    class ValidationError < StandardError; end
    class RateLimitError < StandardError; end
  end
end
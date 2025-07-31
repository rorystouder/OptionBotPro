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
    
    # Transaction History
    def get_transactions(account_id, params = {})
      make_request(:get, "/accounts/#{account_id}/transactions", params)
    end
    
    # Watchlist Methods
    def get_watchlists
      make_request(:get, "/watchlists")
    end
    
    def create_watchlist(name, symbols)
      body = { name: name, symbols: symbols }
      make_request(:post, "/watchlists", nil, body)
    end
    
    def get_watchlist(watchlist_id)
      make_request(:get, "/watchlists/#{watchlist_id}")
    end
    
    def update_watchlist(watchlist_id, symbols)
      body = { symbols: symbols }
      make_request(:put, "/watchlists/#{watchlist_id}", nil, body)
    end
    
    def delete_watchlist(watchlist_id)
      make_request(:delete, "/watchlists/#{watchlist_id}")
    end
    
    # Market Information
    def get_market_hours(date = Date.current)
      make_request(:get, "/market-calendar/#{date.to_s}")
    end
    
    def get_option_expirations(symbol)
      make_request(:get, "/option-chains/#{symbol}/expirations")
    end
    
    # Greeks and Analytics
    def get_option_analytics(symbol, expiration)
      make_request(:get, "/option-analytics/#{symbol}/#{expiration}")
    end
    
    # Account History
    def get_account_history(account_id, params = {})
      make_request(:get, "/accounts/#{account_id}/history", params)
    end
    
    # Batch Operations
    def place_orders_batch(account_id, orders)
      body = { orders: orders.map { |order| build_order_body(order) } }
      make_request(:post, "/accounts/#{account_id}/orders/batch", nil, body)
    end
    
    def get_quotes_batch(symbols, fields = nil)
      params = { symbols: symbols.join(',') }
      params[:fields] = fields.join(',') if fields
      make_request(:get, "/marketdata/quotes", params)
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
      when 403
        error_message = response.parsed_response&.dig('error', 'message') || response.body
        if error_message.include?('insufficient funds')
          raise InsufficientFundsError, error_message
        elsif error_message.include?('market closed')
          raise MarketClosedError, error_message
        else
          raise ApiError, "Forbidden: #{error_message}"
        end
      when 404
        error_message = response.parsed_response&.dig('error', 'message') || response.body
        if error_message.include?('symbol')
          raise SymbolNotFoundError, "Symbol not found: #{error_message}"
        else
          raise ApiError, "Not found: #{error_message}"
        end
      when 422
        error_message = parse_validation_errors(response)
        if error_message.include?('order')
          raise InvalidOrderError, error_message
        else
          raise ValidationError, error_message
        end
      when 429
        raise RateLimitError, "Rate limit exceeded. Please try again later."
      when 503
        raise MaintenanceError, "TastyTrade API is currently under maintenance"
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
    class TokenExpiredError < ApiError; end
    class ValidationError < ApiError; end
    class RateLimitError < ApiError; end
    class InsufficientFundsError < ApiError; end
    class SymbolNotFoundError < ApiError; end
    class InvalidOrderError < ApiError; end
    class MaintenanceError < ApiError; end
    class MarketClosedError < ApiError; end
  end
end
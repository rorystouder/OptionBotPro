class TradeExecutorService
  include ActiveModel::Model
  
  attr_accessor :user, :account_id
  
  def initialize(user:, account_id: nil)
    @user = user
    @account_id = account_id || user.tastytrade_account_id
    @api_service = Tastytrade::ApiService.new(user)
    @risk_service = RiskManagementService.new(user)
  end
  
  def execute_trade(trade_data)
    Rails.logger.info "[TradeExecutor] Executing #{trade_data[:strategy]} for #{trade_data[:symbol]}"
    
    # Final risk validation
    unless @risk_service.can_place_trade?(
      account_id: @account_id,
      order_cost: trade_data[:max_loss],
      symbol: trade_data[:symbol]
    )
      raise RiskViolationError, "Trade rejected by risk management"
    end
    
    # Build order based on strategy
    order_params = build_order_params(trade_data)
    
    # Place the order
    order_response = @api_service.place_order(@account_id, order_params)
    
    # Record the order in our database
    order = create_order_record(trade_data, order_response)
    
    Rails.logger.info "[TradeExecutor] Order placed: #{order.id} for #{trade_data[:symbol]}"
    
    {
      success: true,
      order_id: order.id,
      tastytrade_order_id: order_response['id'],
      message: "#{trade_data[:strategy]} order placed for #{trade_data[:symbol]}"
    }
    
  rescue => e
    Rails.logger.error "[TradeExecutor] Failed to execute trade: #{e.message}"
    
    {
      success: false,
      error: e.message,
      message: "Failed to place #{trade_data[:strategy]} order for #{trade_data[:symbol]}"
    }
  end
  
  private
  
  def build_order_params(trade_data)
    case trade_data[:strategy]
    when 'Put Credit Spread'
      build_put_credit_spread_order(trade_data)
    when 'Call Credit Spread'
      build_call_credit_spread_order(trade_data)
    when 'Iron Condor'
      build_iron_condor_order(trade_data)
    else
      raise UnsupportedStrategyError, "Strategy #{trade_data[:strategy]} not supported"
    end
  end
  
  def build_put_credit_spread_order(trade_data)
    strikes = parse_legs(trade_data[:legs])
    long_strike = strikes[0].to_f
    short_strike = strikes[1].to_f
    
    {
      order_type: 'limit',
      symbol: trade_data[:symbol],
      action: 'sell_to_open', # Net credit
      price: trade_data[:credit],
      time_in_force: 'day',
      legs: [
        {
          symbol: build_option_symbol(trade_data[:symbol], trade_data[:expiration], short_strike, 'P'),
          action: 'sell_to_open',
          quantity: 1
        },
        {
          symbol: build_option_symbol(trade_data[:symbol], trade_data[:expiration], long_strike, 'P'),
          action: 'buy_to_open',
          quantity: 1
        }
      ]
    }
  end
  
  def build_call_credit_spread_order(trade_data)
    strikes = parse_legs(trade_data[:legs])
    short_strike = strikes[0].to_f
    long_strike = strikes[1].to_f
    
    {
      order_type: 'limit',
      symbol: trade_data[:symbol],
      action: 'sell_to_open',
      price: trade_data[:credit],
      time_in_force: 'day',
      legs: [
        {
          symbol: build_option_symbol(trade_data[:symbol], trade_data[:expiration], short_strike, 'C'),
          action: 'sell_to_open',
          quantity: 1
        },
        {
          symbol: build_option_symbol(trade_data[:symbol], trade_data[:expiration], long_strike, 'C'),
          action: 'buy_to_open',
          quantity: 1
        }
      ]
    }
  end
  
  def build_iron_condor_order(trade_data)
    strikes = parse_legs(trade_data[:legs])
    long_put = strikes[0].to_f
    short_put = strikes[1].to_f
    short_call = strikes[2].to_f
    long_call = strikes[3].to_f
    
    {
      order_type: 'limit',
      symbol: trade_data[:symbol],
      action: 'sell_to_open',
      price: trade_data[:credit],
      time_in_force: 'day',
      legs: [
        {
          symbol: build_option_symbol(trade_data[:symbol], trade_data[:expiration], long_put, 'P'),
          action: 'buy_to_open',
          quantity: 1
        },
        {
          symbol: build_option_symbol(trade_data[:symbol], trade_data[:expiration], short_put, 'P'),
          action: 'sell_to_open',
          quantity: 1
        },
        {
          symbol: build_option_symbol(trade_data[:symbol], trade_data[:expiration], short_call, 'C'),
          action: 'sell_to_open',
          quantity: 1
        },
        {
          symbol: build_option_symbol(trade_data[:symbol], trade_data[:expiration], long_call, 'C'),
          action: 'buy_to_open',
          quantity: 1
        }
      ]
    }
  end
  
  def parse_legs(legs_string)
    # Parse legs like "150/155" or "150/155/165/170"
    legs_string.split('/')
  end
  
  def build_option_symbol(underlying, expiration, strike, option_type)
    # Build option symbol in standard format
    # Example: AAPL240315C00150000 (AAPL Mar 15 2024 $150 Call)
    exp_date = Date.parse(expiration).strftime('%y%m%d')
    strike_formatted = sprintf('%08d', (strike * 1000).to_i)
    
    "#{underlying}#{exp_date}#{option_type}#{strike_formatted}"
  end
  
  def create_order_record(trade_data, api_response)
    Order.create!(
      user: @user,
      account_id: @account_id,
      symbol: trade_data[:symbol],
      strategy: trade_data[:strategy],
      legs: trade_data[:legs],
      expiration: trade_data[:expiration],
      action: 'sell_to_open',
      quantity: 1,
      order_type: 'limit',
      price: trade_data[:credit],
      time_in_force: 'day',
      status: 'pending',
      tastytrade_order_id: api_response['id'],
      expected_credit: trade_data[:credit],
      max_loss: trade_data[:max_loss],
      pop: trade_data[:pop],
      thesis: trade_data[:thesis],
      model_score: trade_data[:model_score],
      momentum_z: trade_data[:momentum_z],
      flow_z: trade_data[:flow_z]
    )
  end
  
  class RiskViolationError < StandardError; end
  class UnsupportedStrategyError < StandardError; end
end
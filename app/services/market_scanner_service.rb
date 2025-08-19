class MarketScannerService
  include ActiveModel::Model

  SCAN_INTERVAL = 5.minutes
  MAX_TRADES_PER_CYCLE = 5
  MIN_POP = 0.65  # 65% probability of profit
  MIN_RISK_REWARD = 0.33  # 1:3 risk/reward ratio
  MAX_LOSS_PER_TRADE_PERCENTAGE = 0.5  # 0.5% of NAV

  attr_accessor :user, :account_id

  def initialize(user:, account_id: nil)
    @user = user
    @account_id = account_id || user.tastytrade_account_id
    @api_service = Tastytrade::ApiService.new(user)
    @risk_service = RiskManagementService.new(user, @account_id)
  end

  def scan_for_opportunities
    scan_result = scan_for_opportunities_with_details
    scan_result[:trades]
  end

  def scan_for_opportunities_with_details
    Rails.logger.info "[MarketScanner] Starting scan for user #{user.id}"
    start_time = Time.current

    # Initialize scan metadata
    scan_metadata = {
      scan_start: start_time,
      scan_mode: nil,
      symbols_requested: [],
      symbols_scanned: 0,
      symbols_with_opportunities: 0,
      total_opportunities_found: 0,
      opportunities_after_filters: 0,
      filters_applied: [],
      scan_criteria: {
        min_pop: MIN_POP,
        min_risk_reward: MIN_RISK_REWARD,
        max_loss_percentage: MAX_LOSS_PER_TRADE_PERCENTAGE,
        max_trades_per_cycle: MAX_TRADES_PER_CYCLE
      }
    }

    # Check if user has TastyTrade authentication
    if !@user.tastytrade_authenticated?
      Rails.logger.info "[MarketScanner] User not authenticated, returning demo trades"
      scan_metadata[:scan_mode] = "demo"
      demo_trades = generate_demo_trades_with_details
      scan_metadata[:scan_end] = Time.current
      scan_metadata[:scan_duration_ms] = ((Time.current - start_time) * 1000).round
      scan_metadata[:symbols_requested] = demo_trades[:symbols]
      scan_metadata[:symbols_scanned] = demo_trades[:symbols].size
      scan_metadata[:symbols_with_opportunities] = demo_trades[:trades].size
      scan_metadata[:total_opportunities_found] = demo_trades[:trades].size
      scan_metadata[:opportunities_after_filters] = demo_trades[:trades].size

      return {
        trades: demo_trades[:trades],
        metadata: scan_metadata
      }
    end

    scan_metadata[:scan_mode] = "live"
    candidates = []
    symbols_with_data = []

    # Get watchlist symbols (for now, using popular options trading symbols)
    symbols = get_watchlist_symbols
    scan_metadata[:symbols_requested] = symbols

    # Scan each symbol for opportunities
    symbols.each do |symbol|
      begin
        opportunities = scan_symbol(symbol)
        if opportunities.any?
          candidates.concat(opportunities)
          symbols_with_data << symbol
          scan_metadata[:symbols_with_opportunities] += 1
        end
        scan_metadata[:symbols_scanned] += 1
      rescue => e
        Rails.logger.error "[MarketScanner] Error scanning #{symbol}: #{e.message}"
      end
    end

    scan_metadata[:total_opportunities_found] = candidates.size

    # Apply hard filters
    scan_metadata[:filters_applied] = [ "POP >= #{MIN_POP}", "Risk/Reward >= #{MIN_RISK_REWARD}", "Max Loss <= #{MAX_LOSS_PER_TRADE_PERCENTAGE}% NAV" ]
    filtered_candidates = apply_hard_filters(candidates)
    scan_metadata[:opportunities_after_filters] = filtered_candidates.size

    # Rank and select top trades
    selected_trades = select_top_trades(filtered_candidates)

    scan_metadata[:scan_end] = Time.current
    scan_metadata[:scan_duration_ms] = ((Time.current - start_time) * 1000).round

    Rails.logger.info "[MarketScanner] Scan complete: #{selected_trades.size} trades selected from #{candidates.size} candidates across #{symbols.size} symbols"

    {
      trades: selected_trades,
      metadata: scan_metadata
    }
  end

  def scan_symbol(symbol)
    opportunities = []

    # Get current market data
    quote = @api_service.get_quote(symbol)
    return [] unless quote && quote_fresh?(quote)

    # Get options chain
    chain = @api_service.get_option_chain(symbol)
    return [] unless chain

    # Analyze put credit spreads
    put_spreads = analyze_put_credit_spreads(symbol, quote, chain)
    opportunities.concat(put_spreads)

    # Analyze iron condors
    condors = analyze_iron_condors(symbol, quote, chain)
    opportunities.concat(condors)

    # Analyze call credit spreads
    call_spreads = analyze_call_credit_spreads(symbol, quote, chain)
    opportunities.concat(call_spreads)

    opportunities
  end

  private

  def get_watchlist_symbols
    # For now, return popular liquid options symbols
    # TODO: Integrate with user's watchlist or screener
    %w[SPY QQQ AAPL MSFT GOOGL AMZN TSLA NVDA META JPM BAC XLF XLE IWM DIA GLD SLV VXX TLT]
  end

  def quote_fresh?(quote)
    return false unless quote["updated_at"]
    Time.parse(quote["updated_at"]) > 10.minutes.ago
  end

  def analyze_put_credit_spreads(symbol, quote, chain)
    opportunities = []
    current_price = quote["last"].to_f

    # Look for 30-45 DTE options
    expiration_dates = filter_expirations(chain, 30, 45)

    expiration_dates.each do |expiration|
      puts = chain["puts"][expiration] || []

      # Find strikes around 1 standard deviation below current price
      target_short_strike = current_price * 0.84  # Approximately 1 SD

      puts.each_cons(2) do |short_put, long_put|
        next unless short_put["strike"].to_f <= target_short_strike
        next unless long_put["strike"].to_f < short_put["strike"].to_f

        # Calculate credit and POP
        credit = short_put["bid"].to_f - long_put["ask"].to_f
        max_loss = (short_put["strike"].to_f - long_put["strike"].to_f) * 100 - credit * 100

        next if credit <= 0 || max_loss <= 0

        risk_reward = credit * 100 / max_loss
        pop = calculate_pop_put_spread(short_put, current_price)

        opportunities << {
          symbol: symbol,
          strategy: "Put Credit Spread",
          legs: "#{long_put['strike']}/#{short_put['strike']}",
          expiration: expiration,
          credit: credit,
          max_loss: max_loss,
          risk_reward: risk_reward,
          pop: pop,
          model_score: calculate_model_score(symbol, quote, short_put),
          momentum_z: calculate_momentum_z(symbol, quote),
          flow_z: calculate_flow_z(short_put, long_put),
          thesis: generate_thesis(symbol, "put_credit_spread", quote, short_put)
        }
      end
    end

    opportunities
  end

  def analyze_iron_condors(symbol, quote, chain)
    opportunities = []
    current_price = quote["last"].to_f

    expiration_dates = filter_expirations(chain, 30, 45)

    expiration_dates.each do |expiration|
      puts = chain["puts"][expiration] || []
      calls = chain["calls"][expiration] || []

      next if puts.size < 4 || calls.size < 4

      # Find strikes for iron condor
      put_short_strike = current_price * 0.84
      call_short_strike = current_price * 1.16

      # Find best put spread
      put_spread = find_best_spread(puts, put_short_strike, "put")
      next unless put_spread

      # Find best call spread
      call_spread = find_best_spread(calls, call_short_strike, "call")
      next unless call_spread

      # Calculate combined metrics
      total_credit = put_spread[:credit] + call_spread[:credit]
      max_loss = [ put_spread[:max_loss], call_spread[:max_loss] ].max
      risk_reward = total_credit / max_loss

      # Calculate combined POP (assuming independence)
      combined_pop = put_spread[:pop] * call_spread[:pop]

      opportunities << {
        symbol: symbol,
        strategy: "Iron Condor",
        legs: "#{put_spread[:long_strike]}/#{put_spread[:short_strike]}/#{call_spread[:short_strike]}/#{call_spread[:long_strike]}",
        expiration: expiration,
        credit: total_credit,
        max_loss: max_loss,
        risk_reward: risk_reward,
        pop: combined_pop,
        model_score: calculate_model_score(symbol, quote, nil),
        momentum_z: calculate_momentum_z(symbol, quote),
        flow_z: (put_spread[:flow_z] + call_spread[:flow_z]) / 2,
        thesis: generate_thesis(symbol, "iron_condor", quote, nil)
      }
    end

    opportunities
  end

  def analyze_call_credit_spreads(symbol, quote, chain)
    opportunities = []
    current_price = quote["last"].to_f

    expiration_dates = filter_expirations(chain, 30, 45)

    expiration_dates.each do |expiration|
      calls = chain["calls"][expiration] || []

      # Find strikes around 1 standard deviation above current price
      target_short_strike = current_price * 1.16

      calls.each_cons(2) do |short_call, long_call|
        next unless short_call["strike"].to_f >= target_short_strike
        next unless long_call["strike"].to_f > short_call["strike"].to_f

        credit = short_call["bid"].to_f - long_call["ask"].to_f
        max_loss = (long_call["strike"].to_f - short_call["strike"].to_f) * 100 - credit * 100

        next if credit <= 0 || max_loss <= 0

        risk_reward = credit * 100 / max_loss
        pop = calculate_pop_call_spread(short_call, current_price)

        opportunities << {
          symbol: symbol,
          strategy: "Call Credit Spread",
          legs: "#{short_call['strike']}/#{long_call['strike']}",
          expiration: expiration,
          credit: credit,
          max_loss: max_loss,
          risk_reward: risk_reward,
          pop: pop,
          model_score: calculate_model_score(symbol, quote, short_call),
          momentum_z: calculate_momentum_z(symbol, quote),
          flow_z: calculate_flow_z(short_call, long_call),
          thesis: generate_thesis(symbol, "call_credit_spread", quote, short_call)
        }
      end
    end

    opportunities
  end

  def filter_expirations(chain, min_dte, max_dte)
    return [] unless chain["expirations"]

    today = Date.current

    chain["expirations"].select do |exp_date|
      exp = Date.parse(exp_date)
      dte = (exp - today).to_i
      dte >= min_dte && dte <= max_dte
    end
  end

  def find_best_spread(options, target_strike, type)
    best_spread = nil
    best_credit = 0

    options.each_cons(2) do |short_opt, long_opt|
      if type == "put"
        next unless short_opt["strike"].to_f <= target_strike
        next unless long_opt["strike"].to_f < short_opt["strike"].to_f
      else  # call
        next unless short_opt["strike"].to_f >= target_strike
        next unless long_opt["strike"].to_f > short_opt["strike"].to_f
      end

      credit = short_opt["bid"].to_f - long_opt["ask"].to_f

      if credit > best_credit
        best_credit = credit
        max_loss = (long_opt["strike"].to_f - short_opt["strike"].to_f).abs * 100 - credit * 100

        best_spread = {
          short_strike: short_opt["strike"].to_f,
          long_strike: long_opt["strike"].to_f,
          credit: credit,
          max_loss: max_loss,
          pop: type == "put" ?
            calculate_pop_put_spread(short_opt, short_opt["underlying_price"].to_f) :
            calculate_pop_call_spread(short_opt, short_opt["underlying_price"].to_f),
          flow_z: calculate_flow_z(short_opt, long_opt)
        }
      end
    end

    best_spread
  end

  def calculate_pop_put_spread(option, current_price)
    # Simplified POP calculation based on delta
    # POP ≈ 1 - |delta| for OTM options
    delta = option["delta"].to_f.abs
    [ 1 - delta, 0.5 ].max  # Ensure minimum 50% POP
  end

  def calculate_pop_call_spread(option, current_price)
    delta = option["delta"].to_f.abs
    [ 1 - delta, 0.5 ].max
  end

  def calculate_model_score(symbol, quote, option)
    # Simplified model score based on IV rank and other factors
    score = 0.0

    # IV rank component (higher is better for selling)
    if quote["iv_rank"]
      score += quote["iv_rank"].to_f / 100 * 0.4
    end

    # Liquidity component
    if quote["volume"] && quote["avg_volume"]
      liquidity_ratio = quote["volume"].to_f / quote["avg_volume"].to_f
      score += [ liquidity_ratio, 1.0 ].min * 0.3
    end

    # Technical component (simplified)
    if quote["price_change_percent"]
      # Prefer range-bound stocks
      volatility_factor = 1 - ([ quote["price_change_percent"].to_f.abs / 5, 1.0 ].min)
      score += volatility_factor * 0.3
    end

    score
  end

  def calculate_momentum_z(symbol, quote)
    # Simplified momentum z-score
    return 0.0 unless quote["price_change_percent"]

    # Normalize price change to z-score (simplified)
    price_change = quote["price_change_percent"].to_f
    price_change / 2.0  # Assume 2% = 1 standard deviation
  end

  def calculate_flow_z(short_option, long_option)
    # Simplified option flow z-score based on volume/OI ratio
    short_flow = short_option["volume"].to_f / [ short_option["open_interest"].to_f, 1 ].max
    long_flow = long_option["volume"].to_f / [ long_option["open_interest"].to_f, 1 ].max

    # Average flow, normalized
    avg_flow = (short_flow + long_flow) / 2
    [ avg_flow - 0.5, -2.0 ].max.clamp(-2.0, 2.0)  # Convert to z-score
  end

  def generate_thesis(symbol, strategy, quote, option)
    case strategy
    when "put_credit_spread"
      "High IV rank #{(quote['iv_rank'] || 0).round}% with support near strike, bullish momentum"
    when "call_credit_spread"
      "Elevated IV #{(quote['iv_rank'] || 0).round}% with resistance above, overbought conditions"
    when "iron_condor"
      "Range-bound with high IV rank #{(quote['iv_rank'] || 0).round}%, expecting consolidation"
    else
      "Premium collection opportunity with favorable risk/reward"
    end
  end

  def apply_hard_filters(candidates)
    candidates.select do |trade|
      # Quote freshness - already checked in scan_symbol

      # Probability of Profit
      next false unless trade[:pop] >= MIN_POP

      # Risk/Reward ratio
      next false unless trade[:risk_reward] >= MIN_RISK_REWARD

      # Position sizing
      account_nav = get_account_nav
      max_loss_allowed = account_nav * MAX_LOSS_PER_TRADE_PERCENTAGE / 100
      next false unless trade[:max_loss] <= max_loss_allowed

      # Risk management check
      next false unless @risk_service.can_place_trade?(
        account_id: @account_id,
        order_cost: trade[:max_loss],
        symbol: trade[:symbol]
      )

      true
    end
  end

  def select_top_trades(candidates)
    return [] if candidates.empty?

    # Group by sector to ensure diversification
    sectors = group_by_sector(candidates)

    selected = []
    used_sectors = Set.new

    # Sort all candidates by model_score, then momentum_z, then flow_z
    sorted_candidates = candidates.sort_by do |trade|
      [ -trade[:model_score], -trade[:momentum_z], -trade[:flow_z] ]
    end

    # Select top trades with sector diversification
    sorted_candidates.each do |trade|
      sector = get_sector(trade[:symbol])

      # Check sector limit (max 2 per sector)
      sector_count = selected.count { |t| get_sector(t[:symbol]) == sector }
      next if sector_count >= 2

      selected << trade
      used_sectors << sector

      break if selected.size >= MAX_TRADES_PER_CYCLE
    end

    # Check portfolio Greeks constraints
    if meets_portfolio_constraints?(selected)
      selected
    else
      adjust_for_constraints(selected, sorted_candidates)
    end
  end

  def get_account_nav
    # Get account net asset value
    account = @api_service.get_account(@account_id)
    return 100_000.0 unless account  # Default for testing

    account["net_liquidating_value"].to_f
  end

  def group_by_sector(trades)
    trades.group_by { |trade| get_sector(trade[:symbol]) }
  end

  def get_sector(symbol)
    # Simplified sector mapping
    # TODO: Integrate with real sector data
    sector_map = {
      "SPY" => "Index", "QQQ" => "Index", "IWM" => "Index", "DIA" => "Index",
      "AAPL" => "Technology", "MSFT" => "Technology", "GOOGL" => "Technology",
      "AMZN" => "Consumer", "TSLA" => "Consumer", "META" => "Technology",
      "NVDA" => "Technology", "JPM" => "Financial", "BAC" => "Financial",
      "XLF" => "Financial", "XLE" => "Energy", "GLD" => "Commodity",
      "SLV" => "Commodity", "VXX" => "Volatility", "TLT" => "Bonds"
    }

    sector_map[symbol] || "Other"
  end

  def meets_portfolio_constraints?(trades)
    # Calculate portfolio Greeks
    net_delta = 0.0
    net_vega = 0.0

    trades.each do |trade|
      # Simplified Greeks calculation
      # TODO: Get actual Greeks from options data
      if trade[:strategy] == "Put Credit Spread"
        net_delta += 0.15  # Approximate positive delta
        net_vega -= 0.02   # Negative vega from selling
      elsif trade[:strategy] == "Call Credit Spread"
        net_delta -= 0.15  # Approximate negative delta
        net_vega -= 0.02
      elsif trade[:strategy] == "Iron Condor"
        net_delta += 0.0   # Delta neutral
        net_vega -= 0.04   # Double negative vega
      end
    end

    account_nav = get_account_nav
    nav_factor = account_nav / 100_000

    # Check constraints
    delta_limit = 0.30 * nav_factor
    vega_limit = -0.05 * nav_factor

    net_delta.abs <= delta_limit && net_vega >= vega_limit
  end

  def adjust_for_constraints(selected, all_candidates)
    # If constraints are violated, try to rebalance
    # For now, just return what we have if we can't balance
    # TODO: Implement smart rebalancing algorithm
    selected
  end

  def generate_demo_trades
    result = generate_demo_trades_with_details
    result[:trades]
  end

  def generate_demo_trades_with_details
    # Generate realistic demo trades for testing without API connection
    demo_trades = [
      {
        symbol: "SPY",
        strategy: "Put Credit Spread",
        legs: "575/570",
        expiration: (Date.current + 35.days).to_s,
        credit: 1.25,
        max_loss: 375,
        risk_reward: 0.33,
        pop: 0.72,
        model_score: 0.85,
        momentum_z: 0.5,
        flow_z: 0.3,
        thesis: "SPY showing bullish momentum with support at 570, IV rank 45%",
        current_price: 580.25,
        iv_rank: 45,
        delta: -0.28,
        theta: 0.12,
        vega: -0.08,
        days_to_expiration: 35
      },
      {
        symbol: "AAPL",
        strategy: "Call Credit Spread",
        legs: "235/240",
        expiration: (Date.current + 30.days).to_s,
        credit: 1.10,
        max_loss: 390,
        risk_reward: 0.28,
        pop: 0.68,
        model_score: 0.78,
        momentum_z: -0.3,
        flow_z: 0.2,
        thesis: "AAPL at resistance level, overbought RSI, elevated IV rank 52%",
        current_price: 228.50,
        iv_rank: 52,
        delta: 0.32,
        theta: 0.10,
        vega: -0.06,
        days_to_expiration: 30
      },
      {
        symbol: "QQQ",
        strategy: "Iron Condor",
        legs: "485/480/520/525",
        expiration: (Date.current + 40.days).to_s,
        credit: 2.20,
        max_loss: 280,
        risk_reward: 0.79,
        pop: 0.75,
        model_score: 0.92,
        momentum_z: 0.1,
        flow_z: -0.1,
        thesis: "QQQ range-bound between support/resistance, high IV rank 58%",
        current_price: 502.75,
        iv_rank: 58,
        delta: -0.02,
        theta: 0.18,
        vega: -0.12,
        days_to_expiration: 40
      },
      {
        symbol: "NVDA",
        strategy: "Put Credit Spread",
        legs: "125/120",
        expiration: (Date.current + 28.days).to_s,
        credit: 0.95,
        max_loss: 405,
        risk_reward: 0.23,
        pop: 0.66,
        model_score: 0.71,
        momentum_z: 0.8,
        flow_z: 0.6,
        thesis: "NVDA strong uptrend with AI sector momentum, IV rank 38%",
        current_price: 132.40,
        iv_rank: 38,
        delta: -0.34,
        theta: 0.08,
        vega: -0.05,
        days_to_expiration: 28
      },
      {
        symbol: "TSLA",
        strategy: "Put Credit Spread",
        legs: "250/245",
        expiration: (Date.current + 32.days).to_s,
        credit: 1.35,
        max_loss: 365,
        risk_reward: 0.37,
        pop: 0.70,
        model_score: 0.82,
        momentum_z: 0.4,
        flow_z: 0.5,
        thesis: "TSLA bouncing off support, bullish flow detected, IV rank 62%",
        current_price: 258.90,
        iv_rank: 62,
        delta: -0.30,
        theta: 0.14,
        vega: -0.09,
        days_to_expiration: 32
      }
    ]

    symbols_list = demo_trades.map { |t| t[:symbol] }.uniq

    Rails.logger.info "[MarketScanner] Generated #{demo_trades.size} demo trades for #{symbols_list.size} symbols"

    {
      trades: demo_trades,
      symbols: symbols_list
    }
  end
end

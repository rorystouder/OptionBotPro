class SandboxTestService
  include ActiveModel::Model

  attr_accessor :user

  def initialize(user: nil)
    @user = user || create_test_user
    @api_service = Tastytrade::ApiService.new(@user)
    @scanner_service = MarketScannerService.new(user: @user)
    @executor_service = TradeExecutorService.new(user: @user)
    @results = {}
  end

  def run_full_test_suite
    Rails.logger.info "[SandboxTest] Starting full test suite for user #{@user.id}"

    @results = {
      timestamp: Time.current,
      user_id: @user.id,
      environment: Rails.env,
      tests: {}
    }

    # Test 1: API Authentication
    test_api_authentication

    # Test 2: Market Data Retrieval
    test_market_data_retrieval

    # Test 3: Scanner Functionality
    test_scanner_functionality

    # Test 4: Risk Management
    test_risk_management

    # Test 5: Order Placement (Sandbox)
    test_order_placement

    # Test 6: Trade Execution Pipeline
    test_trade_execution_pipeline

    # Generate test report
    generate_test_report

    @results
  end

  private

  def test_api_authentication
    Rails.logger.info "[SandboxTest] Testing API authentication"

    begin
      accounts = @api_service.get_accounts

      @results[:tests][:authentication] = {
        status: accounts.present? ? "PASS" : "FAIL",
        message: accounts.present? ? "Retrieved #{accounts.size} accounts" : "No accounts found",
        data: accounts&.first&.slice("account-number", "nickname", "account-type-name")
      }
    rescue => e
      @results[:tests][:authentication] = {
        status: "FAIL",
        message: "Authentication failed: #{e.message}",
        error: e.class.name
      }
    end
  end

  def test_market_data_retrieval
    Rails.logger.info "[SandboxTest] Testing market data retrieval"

    test_symbols = %w[SPY AAPL QQQ]
    successful_quotes = 0

    test_symbols.each do |symbol|
      begin
        quote = @api_service.get_quote(symbol)
        successful_quotes += 1 if quote&.dig("last")
      rescue => e
        Rails.logger.warn "[SandboxTest] Failed to get quote for #{symbol}: #{e.message}"
      end
    end

    @results[:tests][:market_data] = {
      status: successful_quotes > 0 ? "PASS" : "FAIL",
      message: "Retrieved quotes for #{successful_quotes}/#{test_symbols.size} symbols",
      symbols_tested: test_symbols,
      success_rate: (successful_quotes.to_f / test_symbols.size * 100).round(1)
    }
  end

  def test_scanner_functionality
    Rails.logger.info "[SandboxTest] Testing scanner functionality"

    begin
      # Use mock data for sandbox testing
      mock_scanner_data if Rails.application.config.respond_to?(:mock_market_data) &&
                           Rails.application.config.mock_market_data

      opportunities = @scanner_service.scan_for_opportunities

      @results[:tests][:scanner] = {
        status: "PASS",
        message: "Scanner found #{opportunities.size} opportunities",
        opportunities_found: opportunities.size,
        strategies: opportunities.map { |o| o[:strategy] }.uniq,
        sample_trade: opportunities.first&.slice(:symbol, :strategy, :pop, :risk_reward)
      }
    rescue => e
      @results[:tests][:scanner] = {
        status: "FAIL",
        message: "Scanner failed: #{e.message}",
        error: e.class.name
      }
    end
  end

  def test_risk_management
    Rails.logger.info "[SandboxTest] Testing risk management"

    risk_service = RiskManagementService.new(@user)

    # Test normal trade
    normal_trade = {
      account_id: @user.tastytrade_account_id,
      order_cost: 100.0,  # $100 trade
      symbol: "SPY"
    }

    # Test excessive trade (should fail)
    excessive_trade = {
      account_id: @user.tastytrade_account_id,
      order_cost: 50000.0,  # $50K trade (should exceed limits)
      symbol: "SPY"
    }

    normal_result = risk_service.can_place_trade?(normal_trade)
    excessive_result = risk_service.can_place_trade?(excessive_trade)

    @results[:tests][:risk_management] = {
      status: (normal_result && !excessive_result) ? "PASS" : "FAIL",
      message: "Normal trade: #{normal_result ? 'Approved' : 'Rejected'}, Excessive trade: #{excessive_result ? 'Approved' : 'Rejected'}",
      normal_trade_approved: normal_result,
      excessive_trade_rejected: !excessive_result,
      cash_reserve_percentage: @user.portfolio_protections.first&.cash_reserve_percentage
    }
  end

  def test_order_placement
    Rails.logger.info "[SandboxTest] Testing order placement in sandbox"

    # Test market order (should fill at $1 in sandbox)
    market_order_params = {
      order_type: "market",
      symbol: "SPY",
      quantity: 1,
      action: "buy-to-open",
      time_in_force: "day"
    }

    # Test limit order with price <= $3 (should fill immediately)
    limit_order_params = {
      order_type: "limit",
      symbol: "AAPL",
      quantity: 1,
      action: "buy-to-open",
      price: 2.50,
      time_in_force: "day"
    }

    # Test limit order with price > $3 (should stay live)
    live_order_params = {
      order_type: "limit",
      symbol: "QQQ",
      quantity: 1,
      action: "buy-to-open",
      price: 5.00,
      time_in_force: "day"
    }

    orders_placed = []

    [
      [ "market", market_order_params ],
      [ "limit_fill", limit_order_params ],
      [ "limit_live", live_order_params ]
    ].each do |test_name, params|
      begin
        response = @api_service.place_order(@user.tastytrade_account_id, params)
        orders_placed << {
          test: test_name,
          status: "placed",
          order_id: response["id"],
          expected_behavior: get_expected_behavior(test_name)
        }
      rescue => e
        orders_placed << {
          test: test_name,
          status: "failed",
          error: e.message,
          expected_behavior: get_expected_behavior(test_name)
        }
      end
    end

    @results[:tests][:order_placement] = {
      status: orders_placed.any? { |o| o[:status] == "placed" } ? "PASS" : "FAIL",
      message: "Placed #{orders_placed.count { |o| o[:status] == 'placed' }}/3 test orders",
      orders: orders_placed
    }
  end

  def test_trade_execution_pipeline
    Rails.logger.info "[SandboxTest] Testing full trade execution pipeline"

    # Create a mock trade opportunity
    mock_trade = {
      symbol: "SPY",
      strategy: "Put Credit Spread",
      legs: "400/395",
      expiration: (Date.current + 30.days).to_s,
      credit: 0.75,
      max_loss: 425.0,
      pop: 0.72,
      risk_reward: 0.18,
      model_score: 0.85,
      momentum_z: 0.5,
      flow_z: -0.2,
      thesis: "Sandbox test trade with high IV and support levels"
    }

    begin
      result = @executor_service.execute_trade(mock_trade)

      @results[:tests][:execution_pipeline] = {
        status: result[:success] ? "PASS" : "FAIL",
        message: result[:message],
        order_created: result[:success],
        order_id: result[:order_id],
        trade_data: mock_trade.slice(:symbol, :strategy, :credit, :max_loss)
      }
    rescue => e
      @results[:tests][:execution_pipeline] = {
        status: "FAIL",
        message: "Execution failed: #{e.message}",
        error: e.class.name
      }
    end
  end

  def mock_scanner_data
    # Mock API responses for scanner testing
    allow(@scanner_service).to receive(:get_watchlist_symbols).and_return(%w[SPY QQQ AAPL])

    # Mock quote data
    mock_quote = {
      "last" => 450.00,
      "updated_at" => Time.current.iso8601,
      "iv_rank" => 75,
      "volume" => 1000000,
      "avg_volume" => 800000,
      "price_change_percent" => 0.5
    }

    allow(@api_service).to receive(:get_quote).and_return(mock_quote)

    # Mock options chain data
    mock_chain = {
      "expirations" => [ (Date.current + 30.days).to_s ],
      "puts" => {
        (Date.current + 30.days).to_s => [
          { "strike" => "400", "bid" => 1.50, "ask" => 1.55, "delta" => -0.25, "volume" => 100, "open_interest" => 1000 },
          { "strike" => "395", "bid" => 1.00, "ask" => 1.05, "delta" => -0.20, "volume" => 150, "open_interest" => 1200 }
        ]
      },
      "calls" => {
        (Date.current + 30.days).to_s => [
          { "strike" => "500", "bid" => 1.20, "ask" => 1.25, "delta" => 0.25, "volume" => 80, "open_interest" => 900 },
          { "strike" => "505", "bid" => 0.90, "ask" => 0.95, "delta" => 0.20, "volume" => 120, "open_interest" => 1100 }
        ]
      }
    }

    allow(@api_service).to receive(:get_option_chain).and_return(mock_chain)
  end

  def get_expected_behavior(test_name)
    case test_name
    when "market"
      "Should fill immediately at $1.00"
    when "limit_fill"
      "Should fill immediately (price <= $3)"
    when "limit_live"
      "Should remain live/working (price > $3)"
    end
  end

  def create_test_user
    User.find_or_create_by(email: "sandbox.test@example.com") do |user|
      user.first_name = "Sandbox"
      user.last_name = "Tester"
      user.password = "sandbox123"
      user.tastytrade_customer_id = "sandbox-customer-123"
      user.active = true
    end
  end

  def generate_test_report
    Rails.logger.info "[SandboxTest] Generating test report"

    passed_tests = @results[:tests].count { |_, test| test[:status] == "PASS" }
    total_tests = @results[:tests].size

    @results[:summary] = {
      total_tests: total_tests,
      passed_tests: passed_tests,
      failed_tests: total_tests - passed_tests,
      success_rate: (passed_tests.to_f / total_tests * 100).round(1),
      overall_status: passed_tests == total_tests ? "ALL_PASS" : "SOME_FAILED"
    }

    Rails.logger.info "[SandboxTest] Test Summary: #{passed_tests}/#{total_tests} passed (#{@results[:summary][:success_rate]}%)"
  end
end

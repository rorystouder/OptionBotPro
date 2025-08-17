class ScannerController < ApplicationController
  def index
    @recent_scans = current_user.trade_scan_results.order(scan_timestamp: :desc).limit(10)
    @latest_scan = @recent_scans.first
    
    if @latest_scan
      parsed_data = JSON.parse(@latest_scan.scan_data)
      
      # Handle both old and new scan data formats
      if parsed_data.is_a?(Hash) && parsed_data["scan_version"] == "2.0"
        @scan_data = parsed_data["trades"] || []
        @scan_metadata = parsed_data["metadata"] || {}
      else
        # Old format - just array of trades
        @scan_data = parsed_data
        @scan_metadata = {}
      end
    else
      @scan_data = []
      @scan_metadata = {}
    end
  end

  def scan
    if current_user.tastytrade_authenticated?
      # Perform scan immediately (bypassing market hours check for manual scans)
      perform_manual_scan
      redirect_to scanner_path, notice: "Market scan completed. Check results below."
    else
      redirect_to scanner_path, alert: "Please authenticate with TastyTrade first."
    end
  end

  private

  def perform_manual_scan
    scanner = MarketScannerService.new(user: current_user)
    scan_result = scanner.scan_for_opportunities_with_details
    
    # Extract trades and metadata
    selected_trades = scan_result[:trades]
    scan_metadata = scan_result[:metadata]
    
    # Create enhanced scan data with metadata
    enhanced_scan_data = {
      trades: selected_trades,
      metadata: scan_metadata,
      scan_version: "2.0"
    }
    
    # Store scan results with metadata
    TradeScanResult.create!(
      user: current_user,
      scan_timestamp: Time.current,
      trades_found: selected_trades.size,
      scan_data: enhanced_scan_data.to_json
    )
    
    Rails.logger.info "Manual scan completed for user #{current_user.id}: #{selected_trades.size} trades found from #{scan_metadata[:symbols_scanned]} symbols"
  rescue => e
    Rails.logger.error "Manual scan failed for user #{current_user.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def show
    @scan = current_user.trade_scan_results.find(params[:id])
    @scan_data = JSON.parse(@scan.scan_data)
  rescue ActiveRecord::RecordNotFound
    redirect_to scanner_path, alert: "Scan not found."
  end
end

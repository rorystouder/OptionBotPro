class ScannerController < ApplicationController
  def index
    @recent_scans = current_user.trade_scan_results.order(scan_timestamp: :desc).limit(10)
    @latest_scan = @recent_scans.first
    @scan_data = @latest_scan ? JSON.parse(@latest_scan.scan_data) : []
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
    selected_trades = scanner.scan_for_opportunities
    
    # Store scan results
    TradeScanResult.create!(
      user: current_user,
      scan_timestamp: Time.current,
      trades_found: selected_trades.size,
      scan_data: selected_trades.to_json
    )
    
    Rails.logger.info "Manual scan completed for user #{current_user.id}: #{selected_trades.size} trades found"
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

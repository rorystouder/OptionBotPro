class ScannerController < ApplicationController
  def index
    @recent_scans = current_user.trade_scan_results.order(scan_timestamp: :desc).limit(10)
    @latest_scan = @recent_scans.first
    @scan_data = @latest_scan ? JSON.parse(@latest_scan.scan_data) : []
  end

  def scan
    if current_user.tastytrade_authenticated?
      MarketScannerJob.perform_later(current_user.id)
      redirect_to scanner_path, notice: "Market scan initiated. Results will appear shortly."
    else
      redirect_to scanner_path, alert: "Please authenticate with TastyTrade first."
    end
  end

  def show
    @scan = current_user.trade_scan_results.find(params[:id])
    @scan_data = JSON.parse(@scan.scan_data)
  rescue ActiveRecord::RecordNotFound
    redirect_to scanner_path, alert: "Scan not found."
  end
end

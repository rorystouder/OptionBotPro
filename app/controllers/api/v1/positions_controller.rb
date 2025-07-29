class Api::V1::PositionsController < Api::BaseController
  def index
    account_id = params[:account_id]
    
    if account_id.present?
      # Fetch positions from TastyTrade API
      api_service = Tastytrade::ApiService.new(current_user)
      positions_data = api_service.get_positions(account_id)
      
      # Update local database
      sync_positions(positions_data, account_id)
    end
    
    # Return positions from local database
    positions = current_user.positions.includes(:user)
    positions = positions.where(tastytrade_account_id: account_id) if account_id.present?
    
    render_success(positions.as_json(include_unrealized_pnl: true))
  rescue => e
    render_error("Failed to fetch positions: #{e.message}")
  end
  
  def show
    position = current_user.positions.find(params[:id])
    render_success(position.as_json(include_unrealized_pnl: true))
  rescue => e
    render_error("Failed to fetch position: #{e.message}")
  end
  
  private
  
  def sync_positions(positions_data, account_id)
    return unless positions_data&.dig('data', 'items')
    
    positions_data['data']['items'].each do |position_data|
      position = current_user.positions.find_or_initialize_by(
        symbol: position_data['symbol'],
        tastytrade_account_id: account_id
      )
      
      position.assign_attributes(
        quantity: position_data['quantity'],
        average_price: position_data['cost-basis'].to_f / position_data['quantity'].abs,
        current_price: position_data['market-value'].to_f / position_data['quantity'].abs,
        last_updated_at: Time.current
      )
      
      position.save! if position.changed?
    end
    
    # Mark positions not in the API response as closed (quantity = 0)
    current_symbols = positions_data['data']['items'].map { |p| p['symbol'] }
    current_user.positions
                .where(tastytrade_account_id: account_id)
                .where.not(symbol: current_symbols)
                .where.not(quantity: 0)
                .update_all(quantity: 0, last_updated_at: Time.current)
  end
end
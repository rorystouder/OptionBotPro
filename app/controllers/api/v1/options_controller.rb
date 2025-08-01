class Api::V1::OptionsController < Api::BaseController
  def show
    symbol = params[:id].upcase
    expiration_date = params[:expiration_date]

    # Use caching for option chain data
    cache_key = "option_chain:#{symbol}:#{expiration_date}"

    option_chain = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      api_service = Tastytrade::ApiService.new(current_user)
      api_service.get_option_chain(symbol, expiration_date)
    end

    render_success(option_chain)
  rescue => e
    render_error("Failed to fetch option chain: #{e.message}")
  end

  def quotes
    symbols = params[:symbols]

    if symbols.blank?
      render_error("Symbols parameter is required")
      return
    end

    symbols_array = symbols.is_a?(Array) ? symbols : symbols.split(",")
    symbols_array.map!(&:upcase)

    # Use caching for quotes
    cache_key = "quotes:#{symbols_array.sort.join(',')}"

    quotes = Rails.cache.fetch(cache_key, expires_in: 10.seconds) do
      api_service = Tastytrade::ApiService.new(current_user)
      api_service.get_quotes(symbols_array)
    end

    render_success(quotes)
  rescue => e
    render_error("Failed to fetch quotes: #{e.message}")
  end
end

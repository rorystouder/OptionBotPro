class Position < ApplicationRecord
  belongs_to :user
  
  validates :symbol, presence: true, format: { with: /\A[A-Z]+\d*[CP]?\d*\z/ }
  validates :quantity, presence: true, numericality: { other_than: 0 }
  validates :average_price, presence: true, numericality: { greater_than: 0 }
  validates :tastytrade_account_id, presence: true
  
  before_validation :normalize_symbol
  
  scope :long_positions, -> { where('quantity > 0') }
  scope :short_positions, -> { where('quantity < 0') }
  scope :by_symbol, ->(symbol) { where(symbol: symbol.upcase) if symbol.present? }
  scope :options, -> { where('symbol LIKE ?', '%C%').or(where('symbol LIKE ?', '%P%')) }
  scope :stocks, -> { where.not('symbol LIKE ?', '%C%').where.not('symbol LIKE ?', '%P%') }
  
  def long?
    quantity > 0
  end
  
  def short?
    quantity < 0
  end
  
  def option?
    symbol.match?(/\d+[CP]\d+/)
  end
  
  def call_option?
    option? && symbol.include?('C')
  end
  
  def put_option?
    option? && symbol.include?('P')
  end
  
  def stock?
    !option?
  end
  
  def market_value
    return nil unless current_price
    
    current_price * quantity
  end
  
  def unrealized_pnl
    return nil unless current_price
    
    (current_price - average_price) * quantity
  end
  
  def unrealized_pnl_percent
    return nil unless unrealized_pnl
    
    (unrealized_pnl / (average_price * quantity.abs)) * 100
  end
  
  def cost_basis
    average_price * quantity.abs
  end
  
  private
  
  def normalize_symbol
    self.symbol = symbol.upcase if symbol.present?
  end
end
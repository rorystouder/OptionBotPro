class Order < ApplicationRecord
  include AASM
  
  belongs_to :user
  has_many :legs, dependent: :destroy, class_name: 'OrderLeg'
  
  VALID_ORDER_TYPES = %w[market limit stop stop_limit].freeze
  VALID_ACTIONS = %w[buy-to-open buy-to-close sell-to-open sell-to-close].freeze
  VALID_TIME_IN_FORCE = %w[day gtc ioc fok].freeze
  
  validates :symbol, presence: true, format: { with: /\A[A-Z]+\d*[CP]?\d*\z/ }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :order_type, presence: true, inclusion: { in: VALID_ORDER_TYPES }
  validates :action, presence: true, inclusion: { in: VALID_ACTIONS }
  validates :time_in_force, presence: true, inclusion: { in: VALID_TIME_IN_FORCE }
  validates :price, numericality: { greater_than: 0 }, allow_nil: true
  validates :stop_price, numericality: { greater_than: 0 }, allow_nil: true
  validates :tastytrade_order_id, uniqueness: true, allow_nil: true
  
  before_validation :normalize_symbol
  
  aasm column: :status do
    state :pending, initial: true
    state :submitted
    state :working
    state :filled
    state :partially_filled
    state :cancelled
    state :rejected
    state :expired
    
    event :submit do
      transitions from: :pending, to: :submitted
    end
    
    event :accept do
      transitions from: :submitted, to: :working
    end
    
    event :fill do
      transitions from: [:working, :partially_filled], to: :filled
    end
    
    event :partial_fill do
      transitions from: :working, to: :partially_filled
    end
    
    event :cancel do
      transitions from: [:pending, :submitted, :working, :partially_filled], to: :cancelled
    end
    
    event :reject do
      transitions from: [:pending, :submitted], to: :rejected
    end
    
    event :expire do
      transitions from: [:working, :partially_filled], to: :expired
    end
  end
  
  scope :active, -> { where(status: %w[pending submitted working partially_filled]) }
  scope :completed, -> { where(status: %w[filled cancelled rejected expired]) }
  scope :by_symbol, ->(symbol) { where(symbol: symbol.upcase) if symbol.present? }
  
  def market_order?
    order_type == 'market'
  end
  
  def limit_order?
    order_type == 'limit'
  end
  
  def stop_order?
    order_type.include?('stop')
  end
  
  def multi_leg?
    legs.exists?
  end
  
  def total_value
    return price * quantity if price.present?
    
    legs.sum { |leg| (leg.price || 0) * leg.quantity }
  end
  
  private
  
  def normalize_symbol
    self.symbol = symbol.upcase if symbol.present?
  end
end
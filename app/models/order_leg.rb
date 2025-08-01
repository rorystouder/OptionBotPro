class OrderLeg < ApplicationRecord
  belongs_to :order

  VALID_ACTIONS = %w[buy-to-open buy-to-close sell-to-open sell-to-close].freeze

  validates :symbol, presence: true, format: { with: /\A[A-Z]+\d*[CP]?\d*\z/ }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :action, presence: true, inclusion: { in: VALID_ACTIONS }
  validates :price, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :normalize_symbol

  def option?
    symbol.match?(/\d+[CP]\d+/)
  end

  def call_option?
    option? && symbol.include?('C')
  end

  def put_option?
    option? && symbol.include?('P')
  end

  private

  def normalize_symbol
    self.symbol = symbol.upcase if symbol.present?
  end
end
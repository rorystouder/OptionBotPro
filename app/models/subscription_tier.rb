class SubscriptionTier < ApplicationRecord
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :price_monthly, presence: true, numericality: { greater_than: 0 }
  validates :max_daily_trades, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_trading_capital, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_accounts, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :name) }

  before_validation :generate_slug, if: -> { name.present? && slug.blank? }

  def features_list
    return [] if features.blank?
    features.split("\n").map(&:strip).reject(&:blank?)
  end

  def features_list=(list)
    self.features = Array(list).join("\n")
  end

  def unlimited_trades?
    max_daily_trades.blank? || max_daily_trades <= 0
  end

  def unlimited_capital?
    max_trading_capital.blank? || max_trading_capital <= 0
  end

  def basic_tier?
    slug == 'basic'
  end

  def pro_tier?
    slug == 'pro'
  end

  def elite_tier?
    slug == 'elite'
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/-+/, '-').strip('-')
  end
end

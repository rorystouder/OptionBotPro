class User < ApplicationRecord
  has_secure_password
  
  has_many :orders, dependent: :destroy
  has_many :positions, dependent: :destroy
  has_many :strategies, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :tastytrade_customer_id, presence: true
  
  scope :active, -> { where(active: true) }
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def tastytrade_authenticated?
    Rails.cache.exist?("tastytrade_token_#{email}")
  end
end
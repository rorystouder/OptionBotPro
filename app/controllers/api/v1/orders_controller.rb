class Api::V1::OrdersController < Api::BaseController
  before_action :set_order, only: [ :show, :update, :destroy ]

  def index
    orders = current_user.orders.includes(:legs).order(created_at: :desc)
    orders = orders.where(status: params[:status]) if params[:status].present?
    orders = orders.by_symbol(params[:symbol]) if params[:symbol].present?

    # Paginate results
    page = params[:page].to_i.positive? ? params[:page].to_i : 1
    per_page = [ params[:per_page].to_i, 100 ].min.positive? ? [ params[:per_page].to_i, 100 ].min : 20

    orders = orders.limit(per_page).offset((page - 1) * per_page)

    render_success({
      orders: orders.as_json(include: :legs),
      pagination: {
        page: page,
        per_page: per_page,
        total: current_user.orders.count
      }
    })
  end

  def show
    render_success(@order.as_json(include: :legs))
  end

  def create
    validator = OrderValidator.new(order_params)

    unless validator.valid?
      render_error("Invalid order parameters", :unprocessable_entity, validator.errors.full_messages)
      return
    end

    # Validate account ownership
    account_id = params[:order][:account_id]
    if account_id.present? && !validate_account_ownership(account_id)
      render_error("Invalid account ID", :forbidden)
      return
    end

    order = current_user.orders.build(order_params.except(:legs))

    ActiveRecord::Base.transaction do
      order.save!

      # Create order legs if provided
      if order_params[:legs].present?
        order_params[:legs].each_with_index do |leg_params, index|
          order.legs.create!(leg_params.merge(leg_number: index + 1))
        end
      end

      # Submit order to TastyTrade API
      api_service = Tastytrade::ApiService.new(current_user)
      api_response = api_service.place_order(account_id, build_api_order_params(order))

      order.update!(
        tastytrade_order_id: api_response.dig("data", "order-id"),
        tastytrade_account_id: account_id,
        submitted_at: Time.current
      )
      order.submit!

      render_success(order.as_json(include: :legs), "Order submitted successfully", :created)
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error("Failed to create order", :unprocessable_entity, e.record.errors.full_messages)
  rescue => e
    render_error("Failed to submit order: #{e.message}")
  end

  def update
    case params[:action_type]
    when "cancel"
      cancel_order
    when "modify"
      modify_order
    else
      render_error('Invalid action type. Use "cancel" or "modify"')
    end
  end

  def destroy
    cancel_order
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  end

  def order_params
    # Note: :account_id is validated separately in create method for security
    params.require(:order).permit(
      :symbol, :quantity, :order_type, :action, :price, :stop_price,
      :time_in_force,
      legs: [ :symbol, :quantity, :action, :price ]
    )
  end

  def validate_account_ownership(account_id)
    # Fetch user's accounts from TastyTrade API and verify ownership
    api_service = Tastytrade::ApiService.new(current_user)
    accounts = api_service.get_accounts

    # Check if the provided account_id belongs to the current user
    accounts["data"]["accounts"].any? { |account| account["account-number"] == account_id }
  rescue => e
    Rails.logger.error "Failed to validate account ownership: #{e.message}"
    false
  end

  def cancel_order
    return render_error("Order cannot be cancelled") unless @order.may_cancel?

    api_service = Tastytrade::ApiService.new(current_user)
    api_service.cancel_order(@order.tastytrade_account_id, @order.tastytrade_order_id)

    @order.cancel!
    @order.update!(cancelled_at: Time.current)

    render_success(@order, "Order cancelled successfully")
  rescue => e
    render_error("Failed to cancel order: #{e.message}")
  end

  def modify_order
    modifications = params.require(:modifications).permit(:price, :quantity, :time_in_force)

    api_service = Tastytrade::ApiService.new(current_user)
    api_service.replace_order(@order.tastytrade_account_id, @order.tastytrade_order_id, modifications)

    @order.update!(modifications)

    render_success(@order, "Order modified successfully")
  rescue => e
    render_error("Failed to modify order: #{e.message}")
  end

  def build_api_order_params(order)
    params = {
      symbol: order.symbol,
      quantity: order.quantity,
      order_type: order.order_type,
      action: order.action,
      time_in_force: order.time_in_force
    }

    params[:price] = order.price if order.price.present?
    params[:stop_price] = order.stop_price if order.stop_price.present?

    # Add legs for multi-leg orders
    if order.legs.exists?
      params[:legs] = order.legs.map do |leg|
        {
          symbol: leg.symbol,
          quantity: leg.quantity,
          action: leg.action,
          price: leg.price
        }
      end
    end

    params
  end
end

class OrderValidator
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :symbol, :string
  attribute :quantity, :integer
  attribute :order_type, :string
  attribute :action, :string
  attribute :price, :decimal
  attribute :stop_price, :decimal
  attribute :time_in_force, :string
  attribute :account_id, :string

  validates :symbol, presence: true, format: { with: /\A[A-Z]+\d*[CP]?\d*\z/ }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :order_type, presence: true, inclusion: { in: Order::VALID_ORDER_TYPES }
  validates :action, presence: true, inclusion: { in: Order::VALID_ACTIONS }
  validates :time_in_force, presence: true, inclusion: { in: Order::VALID_TIME_IN_FORCE }
  validates :account_id, presence: true
  validates :price, numericality: { greater_than: 0 }, allow_nil: true
  validates :stop_price, numericality: { greater_than: 0 }, allow_nil: true

  validate :price_required_for_limit_orders
  validate :stop_price_required_for_stop_orders

  private

  def price_required_for_limit_orders
    if order_type == "limit" && price.blank?
      errors.add(:price, "is required for limit orders")
    end
  end

  def stop_price_required_for_stop_orders
    if order_type&.include?("stop") && stop_price.blank?
      errors.add(:stop_price, "is required for stop orders")
    end
  end
end

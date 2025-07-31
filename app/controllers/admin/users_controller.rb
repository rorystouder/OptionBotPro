class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  
  def index
    @users = User.includes(:subscription_tier)
                 .order(created_at: :desc)
    @users = @users.where('email ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    @users = @users.where(subscription_status: params[:status]) if params[:status].present?
  end

  def show
    @orders = @user.orders.includes(:order_legs).order(created_at: :desc).limit(20)
    @positions = @user.positions.order(created_at: :desc).limit(10)
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: 'User updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      redirect_to admin_users_path, notice: 'User deleted successfully.'
    else
      redirect_to admin_user_path(@user), alert: 'Cannot delete user with active data.'
    end
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :active, :admin, 
                                 :subscription_tier_id, :subscription_status, 
                                 :trial_ends_at, :subscription_ends_at)
  end
end

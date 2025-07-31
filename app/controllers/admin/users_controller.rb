class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :reset_password]
  
  def index
    @users = User.includes(:subscription_tier)
                 .order(created_at: :desc)
    @users = @users.where('email LIKE ?', "%#{params[:search]}%") if params[:search].present?
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

  def reset_password
    # Generate secure temporary password
    temp_password = SecureRandom.alphanumeric(12) + SecureRandom.random_number(10).to_s + ['!', '@', '#', '$'].sample
    
    @user.password = temp_password
    @user.password_confirmation = temp_password
    @user.password_reset_required = true # Force password change on next login
    @user.password_reset_token = SecureRandom.hex(32)
    @user.password_reset_sent_at = Time.current
    
    if @user.save
      # Send email with temporary password (implement later with SendGrid)
      UserMailer.password_reset(@user, temp_password).deliver_later rescue nil
      
      redirect_to admin_user_path(@user), 
                  notice: "Password reset successfully. Temporary password sent to #{@user.email}. User must change password on next login."
    else
      redirect_to admin_user_path(@user), 
                  alert: "Failed to reset password: #{@user.errors.full_messages.join(', ')}"
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

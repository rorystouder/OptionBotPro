class UsersController < ApplicationController
  skip_before_action :authenticate_user, only: [ :new, :create ]

  def new
    @user = User.new

    if logged_in?
      redirect_to dashboard_path
    end
  end

  def create
    @user = User.new(user_params)

    if @user.save
      @user.initialize_trial
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: "Account created successfully! Your 14-day free trial has started."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(user_params)
      redirect_to user_path, notice: "Profile updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :tastytrade_username, :tastytrade_password)
  end
end

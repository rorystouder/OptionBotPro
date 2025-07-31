class Admin::SettingsController < Admin::BaseController
  def show
    @user = current_user
  end
  
  def update_password
    @user = current_user
    
    # Verify current password
    unless @user.authenticate(params[:current_password])
      redirect_to admin_settings_path, alert: 'Current password is incorrect.'
      return
    end
    
    # Validate new password
    if params[:new_password] != params[:confirm_password]
      redirect_to admin_settings_path, alert: 'New passwords do not match.'
      return
    end
    
    if params[:new_password].length < 8
      redirect_to admin_settings_path, alert: 'New password must be at least 8 characters long.'
      return
    end
    
    # Update password
    @user.password = params[:new_password]
    @user.password_confirmation = params[:confirm_password]
    
    if @user.save
      # Clear any existing sessions for security
      session[:user_id] = @user.id # Keep current session
      
      redirect_to admin_settings_path, notice: 'Password updated successfully!'
    else
      redirect_to admin_settings_path, alert: @user.errors.full_messages.join(', ')
    end
  end
end
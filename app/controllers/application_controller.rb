class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :authenticate_user
  before_action :set_current_user
  
  private
  
  def authenticate_user
    unless logged_in?
      redirect_to login_path, alert: 'Please log in to continue'
    end
  end
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def logged_in?
    !!current_user
  end
  
  def set_current_user
    Current.user = current_user
  end
  
  helper_method :current_user, :logged_in?
end

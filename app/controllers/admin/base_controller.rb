class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!
  
  layout 'admin'
  
  private
  
  def authenticate_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
end
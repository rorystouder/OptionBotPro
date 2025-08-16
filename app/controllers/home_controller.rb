class HomeController < ApplicationController
  skip_before_action :authenticate_user, only: [:index]
  
  def index
    # Redirect to dashboard if already logged in
    if logged_in?
      redirect_to dashboard_path
    end
  end
end

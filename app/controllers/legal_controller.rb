class LegalController < ApplicationController
  skip_before_action :authenticate_user

  def terms
  end

  def privacy
  end

  def risk_disclosure
  end
end

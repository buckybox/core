class ApiController < ApplicationController
  layout false

  def index
    redirect_to new_distributor_session_url unless current_distributor
  end
end

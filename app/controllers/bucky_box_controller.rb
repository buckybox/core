class BuckyBoxController < ApplicationController
  def index
    redirect_to distributor_dashboard_path and return if current_distributor
  end

end

class BuckyBoxController < ApplicationController
  def index
    redirect_to distributor_root_path and return if current_distributor
    redirect_to customer_root_path and return if current_customer
    redirect_to 'http://www.buckybox.com/'
  end
end

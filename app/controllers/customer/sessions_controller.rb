class Customer::SessionsController < Devise::SessionsController
  include Devise::CustomControllerParameters

  def new
    analytical.event('view_customer_sign_in')
    super
  end

  def create
    analytical.event('customer_signed_in')
    params[:customer][:password].strip! rescue nil #Customers copy and paste password from email, sometimes grabbing a bit of whitespace
    super
  end
end


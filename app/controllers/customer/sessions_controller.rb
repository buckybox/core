class Customer::SessionsController < Devise::SessionsController
  include Devise::CustomControllerParameters

  def new
    analytical.event('view_customer_sign_in')
    super
  end

  def create
    analytical.event('customer_signed_in')
    result = super
    CustomerLogin.track(current_customer) unless current_admin.present?
    result
  end

  def destroy
    cookies.delete :current_customers
    super
  end
end


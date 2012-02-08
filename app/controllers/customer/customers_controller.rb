class Customer::CustomersController < Customer::BaseController
  respond_to :html, :xml, :json

  def update
    update! { customer_root_url }
  end
end

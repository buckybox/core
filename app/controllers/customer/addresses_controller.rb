class Customer::AddressesController < Customer::ResourceController
  actions :update

  respond_to :html, :xml, :json

  def update
    update! { customer_root_url }
  end

  protected

  def resource
    current_customer.address
  end
end

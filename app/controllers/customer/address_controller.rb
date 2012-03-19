class Customer::AddressController < Customer::ResourceController
  actions :update

  respond_to :html, :xml, :json
  
  def resource
    current_customer.address
  end

  def update
    update! { customer_root_url }
  end
end

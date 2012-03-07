class Customer::AddressController < Customer::ResourceController
  actions :update

  belongs_to :customer, singleton: true

  respond_to :html, :xml, :json

  def update
    update! { customer_root_url }
  end
end

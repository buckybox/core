class Customer::BoxesController < Customer::ResourceController
  actions :show

  respond_to :html, :xml, :json

  protected

  def begin_of_association_chain
    current_customer.distributor
  end
end

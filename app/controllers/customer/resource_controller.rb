class Customer::ResourceController < Customer::BaseController
  inherit_resources

  protected

  def begin_of_association_chain
    current_customer
  end
end


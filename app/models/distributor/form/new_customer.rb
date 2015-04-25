require_relative "edit_customer_profile_fields"

class Distributor::Form::NewCustomer
  include Distributor::Form::EditCustomerProfileFields
  include Distributor::Form::EditCustomerDeliveryDetailsFields

protected

  def customer_args
    args = profile_customer_args.merge(delivery_details_customer_args)
    args.merge(distributor: distributor)
  end

  def address_args
    args = profile_address_args.merge(delivery_details_address_args)
    args.merge(customer: customer)
  end
end

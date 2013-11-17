require_relative "edit_customer_profile_fields"

class Distributor::Form::NewCustomer

  include Distributor::Form::EditCustomerProfileFields
  include Distributor::Form::EditCustomerDeliveryDetailsFields

protected

  def customer_args
    profile_customer_args.merge(delivery_details_customer_args)
  end

  def address_args
    profile_address_args.merge(delivery_details_address_args)
  end

end

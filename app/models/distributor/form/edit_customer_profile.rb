require_relative "edit_customer_profile_fields"

class Distributor::Form::EditCustomerProfile
  include Distributor::Form::EditCustomerProfileFields

protected

  def customer_args
    profile_customer_args
  end

  def address_args
    profile_address_args
  end
end

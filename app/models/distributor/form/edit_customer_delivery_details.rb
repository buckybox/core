require_relative "edit_customer_delivery_details_fields"

class Distributor::Form::EditCustomerDeliveryDetails
  include Distributor::Form::EditCustomerDeliveryDetailsFields

protected

  def customer_args
    delivery_details_customer_args
  end

  def address_args
    delivery_details_address_args
  end
end

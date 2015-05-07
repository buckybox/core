require_relative "../form"

class Customer::Form::UpdateDeliveryAddress < Customer::Form
  include Customer::AddressValidations

  def_delegators :distributor,
    :collect_delivery_note?

  def save
    return false unless valid?

    customer.update_address(address_args, notify_distributor: true)
  end

protected

  def assign_attributes(attributes)
    @address_1     = attributes["address_1"] || address.address_1
    @address_2     = attributes["address_2"] || address.address_2
    @suburb        = attributes["suburb"] || address.suburb
    @city          = attributes["city"] || address.city
    @postcode      = attributes["postcode"] || address.postcode
    @delivery_note = attributes["delivery_note"] || address.delivery_note
  end

private

  def address_args
    {
      address_1:      address_1,
      address_2:      address_2,
      suburb:         suburb,
      city:           city,
      postcode:       postcode,
      delivery_note:  delivery_note,
    }
  end
end

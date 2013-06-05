module Customer::AddressesHelper
  def address_phone_fields(form, distributor)
    PhoneCollection.attributes.map do |type|
      form.input type, required: distributor.require_phone
    end.join.html_safe
  end
end

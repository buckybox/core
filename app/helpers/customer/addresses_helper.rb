module Customer::AddressesHelper
  def address_phone_fields(form, distributor)
    form.input(:mobile_phone, required: distributor.require_phone) <<
    form.input(:home_phone, required: distributor.require_phone) <<
    form.input(:work_phone, required: distributor.require_phone)
  end
end

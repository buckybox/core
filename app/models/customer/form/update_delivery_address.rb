require_relative "../form"

class Customer::Form::UpdateDeliveryAddress < Customer::Form

  attribute :address_1
  attribute :address_2
  attribute :suburb
  attribute :city
  attribute :postcode
  attribute :delivery_note

  def_delegators :distributor,
    :require_address_1?,
    :require_address_2?,
    :require_suburb?,
    :require_city?,
    :require_postcode?,
    :collect_delivery_note?,
    :require_delivery_note?

  validates_presence_of :address_1,      if: -> { require_address_1? }
  validates_presence_of :address_2,      if: -> { require_address_2? }
  validates_presence_of :suburb,         if: -> { require_suburb? }
  validates_presence_of :city,           if: -> { require_city? }
  validates_presence_of :postcode,       if: -> { require_postcode? }
  validates_presence_of :delivery_note,  if: -> { require_delivery_note? }

  def save
    return false unless valid?
    address.update_attributes(address_args)
  end

protected

  def assign_attributes(attributes)
    @address_1     = attributes["address_1"]     || address.address_1
    @address_2     = attributes["address_2"]     || address.address_2
    @suburb        = attributes["suburb"]        || address.suburb
    @city          = attributes["city"]          || address.city
    @postcode      = attributes["postcode"]      || address.postcode
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

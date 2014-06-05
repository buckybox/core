require_relative "../form"

class Customer::Form::UpdateContactDetails < Customer::Form

  attribute :name
  attribute :email
  attribute :mobile_phone
  attribute :home_phone
  attribute :work_phone

  def_delegators :distributor,
    :require_phone?,
    :collect_phone?

  validates_presence_of :name
  validates_presence_of :email
  validate :validate_phone

  def save
    return false unless self.valid?

    customer.update_attributes(customer_args) &&
    address.update_attributes(address_args)
  end

protected

  def assign_attributes(attributes)
    @name         = attributes["name"]         || customer.name
    @email        = attributes["email"]        || customer.email
    @mobile_phone = attributes["mobile_phone"] || address.mobile_phone
    @home_phone   = attributes["home_phone"]   || address.home_phone
    @work_phone   = attributes["work_phone"]   || address.work_phone
  end

private

  def customer_args
    {
      first_name:  name,
      last_name:   nil,
      email:       email,
    }
  end

  def address_args
    {
      mobile_phone:  mobile_phone,
      home_phone:    home_phone,
      work_phone:    work_phone,
    }
  end

  def validate_phone
    if distributor.require_phone && PhoneCollection.attributes.all? { |type| self[type].blank? }
      errors[:phone_number] << "can't be blank"
    end
  end

end

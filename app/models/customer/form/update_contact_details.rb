require_relative "../form"

class Customer::Form::UpdateContactDetails < Customer::Form

  attribute :name
  attribute :email
  attribute :mobile_phone
  attribute :home_phone
  attribute :work_phone

  def_delegators :distributor,
    :require_phone?

  validates_presence_of :name
  validates_presence_of :email
  validates_presence_of :mobile_phone,  if: -> { require_phone? }
  validates_presence_of :home_phone,    if: -> { require_phone? }
  validates_presence_of :work_phone,    if: -> { require_phone? }

  def save
    return false unless self.valid?
    result = customer.update_attributes(customer_args)
    result &&= address.update_attributes(address_args)
    result
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

end

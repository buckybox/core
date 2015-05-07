require_relative "../form"

class Customer::Form::UpdateContactDetails < Customer::Form
  include Customer::PhoneValidations

  attribute :first_name
  attribute :last_name
  attribute :email

  def_delegators :distributor,
    :require_phone?,
    :collect_phone?

  validates_presence_of :first_name
  validates_presence_of :email

  def save
    return false unless self.valid?

    customer.update_attributes(customer_args) &&
      address.update_attributes(address_args)
  end

protected

  def assign_attributes(attributes)
    @first_name   = attributes["first_name"]   || customer.first_name
    @last_name    = attributes["last_name"]    || customer.last_name
    @email        = attributes["email"]        || customer.email
    @mobile_phone = attributes["mobile_phone"] || address.mobile_phone
    @home_phone   = attributes["home_phone"]   || address.home_phone
    @work_phone   = attributes["work_phone"]   || address.work_phone
  end

private

  def customer_args
    {
      first_name:  first_name,
      last_name:   last_name,
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

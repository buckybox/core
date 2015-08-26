require_relative "../form"

class Customer::Form::UpdatePassword < Customer::Form
  attribute :password
  attribute :password_confirmation

  validates_presence_of :password
  validates_presence_of :password_confirmation

  def save
    return false unless self.valid?

    if customer.update_attributes(customer_args)
      true
    else
      @errors = customer.errors
      false
    end
  end

private

  def customer_args
    {
      password:               password,
      password_confirmation:  password_confirmation,
    }
  end
end

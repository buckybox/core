module Devise::ControllerMacros
  def as_admin
    before { admin_sign_in }
  end

  def as_distributor
    before { distributor_sign_in }
  end

  def as_customers
    before { customer_sign_in }
  end
end

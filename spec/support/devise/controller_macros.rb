module Devise::ControllerMacros
  def sign_in_as_admin
    before { admin_sign_in }
  end

  def sign_in_as_distributor
    before { distributor_sign_in }
  end

  def sign_in_as_customer
    before { customer_sign_in }
  end
end

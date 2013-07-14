module Devise::RequestMacros
  def simulate_distributor_sign_in
    before { distributor_sign_in }
  end

  def simulate_customer_sign_in
    before { customer_sign_in }
  end

  def as_distributor
    before { sign_in_as_a_valid_distributor }
  end

  def as_customer
    before { sign_in_as_a_valid_customer }
  end
end

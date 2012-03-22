module Devise::RequestMacros
  def simulate_distributor_sign_in
    before { simulate_distributor_sign_in }
  end

  def simulate_customer
    before { simulate_customer_sign_in }
  end
end

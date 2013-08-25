module Devise::FeatureMacros
  def simulate_sign_in_as_admin
    before { simulate_admin_sign_in }
  end

  def simulate_sign_in_as_distributor
    before { simulate_distributor_sign_in }
  end

  def simulate_sign_in_as_customer
    before { simulate_customer_sign_in }
  end
end


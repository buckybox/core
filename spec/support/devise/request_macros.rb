module Devise::RequestMacros
  def as_distributor
    before { sign_in_as_a_valid_distributor }
  end

  def as_customer
    before { sign_in_as_a_valid_customer }
  end
end

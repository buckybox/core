module Devise::RequestMacros
  def login_as_admin
    before { admin_login }
  end

  def login_as_distributor
    before { distributor_login }
  end

  def login_as_customer
    before { customer_login }
  end
end

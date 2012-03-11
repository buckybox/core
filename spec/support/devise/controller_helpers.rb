module Devise::ControllerHelpers
  def admin_sign_in
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    @admin = Fabricate(:admin)
    sign_in @admin
  end

  def distributor_sign_in
    @request.env["devise.mapping"] = Devise.mappings[:distributor]
    @distributor = Fabricate(:distributor)
    sign_in @distributor
  end

  def customer_sign_in
    @request.env["devise.mapping"] = Devise.mappings[:customer]
    @customer = Fabricate(:customer)
    sign_in @customer
  end
end

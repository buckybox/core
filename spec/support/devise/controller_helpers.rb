module Devise::ControllerHelpers
  def admin_sign_in
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in Fabricate(:admin)
  end

  def distributor_sign_in
    @request.env["devise.mapping"] = Devise.mappings[:distributor]
    sign_in Fabricate(:distributor)
  end

  def customer_sign_in
    @request.env["devise.mapping"] = Devise.mappings[:customer]
    sign_in Fabricate(:customer)
  end
end

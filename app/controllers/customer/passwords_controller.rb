class Customer::PasswordsController < Devise::PasswordsController
  include Devise::CustomControllerParameters

  def new
    super
  end
end

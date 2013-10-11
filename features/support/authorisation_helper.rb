module AuthorisationHelper
  def login_as(auth_object)
    auth_type = get_auth_type(auth_object)
    visit send("new_#{auth_type}_session_path")
    login_with(auth_object.email, auth_object.password, auth_type)
  end

  def get_auth_type(auth_object)
    auth_object.class.to_s.underscore
  end

  def login_with(auth_email, auth_password, auth_type)
    fill_in "#{auth_type}_email", with: auth_email
    fill_in "#{auth_type}_password", with: auth_password
    click_button "Login"
  end

  def create_customer
    Fabricate(:customer, distributor: create_distributor)
  end

  def create_distributor
    Fabricate(:existing_distributor_with_everything)
  end

  def create_admin
    Fabricate(:admin)
  end
end

World(AuthorisationHelper)


module UserSessionHelper
  def login_as(user)
    user_type = user_type(user)

    click_link "Logout" if page.has_link? "Logout"
    visit send("new_#{user_type}_session_path")
    fill_in "#{user_type}_email", with: user.email
    fill_in "#{user_type}_password", with: user.password
    click_button "Login"
  end

  def user_type(user)
    case user
    when Distributor
      "distributor"
    when Customer
      "customer"
    when nil
      raise "The current user is unknown!"
    else
      raise "I don't know this user type!"
    end
  end
end

World(UserSessionHelper)


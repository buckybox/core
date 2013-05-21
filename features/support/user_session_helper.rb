def login_as(user)
  user_type = case user
  when Distributor
    "distributor"
  when Customer
    "customer"
  else
    raise "I don't know this duck!"
  end

  visit send("new_#{user_type}_session_path")
  fill_in "#{user_type}_email", with: user.email
  fill_in "#{user_type}_password", with: user.password
  click_button "Login"
end


def login_as(user)
  visit "/distributors/sign_in"
  fill_in "distributor_email", with: @distributor.email
  fill_in "distributor_password", with: 'password'
  click_button "Login"
end

Given /^I am a distributor$/ do
  @distributor = Fabricate(:distributor,
    password: "password", password_confirmation: 'password'
  )
  step "I have an existing customer"
  login_as(@distributor)
end

Given /^I am on the dashboard$/ do
  visit "/"
end

Given /^a distributor looking at their dashboard$/ do
  step "I am a distributor"
  step "I am on the dashboard"
end

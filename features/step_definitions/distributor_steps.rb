def login_as(user)
  visit "/distributors/sign_in"
  fill_in "Email", :with => @distributor.email
  fill_in "Password", :with => 'password'
  click_button "Sign in"
end

Given /^I am a distributor$/ do
  @distributor = Fabricate(:distributor, :password => "password", :password_confirmation => 'password')
  @customer1 = Fabricate(:customer, :distributor => @distributor)
  login_as(@distributor)
end

Given /^I am on the dashboard$/ do
  visit "/distributors"
end

Given /^a distributor looking at their dashboard$/ do
  step "I am a distributor"
  step "I am on the dashboard"
end

When /^I submit valid payment details$/ do
  select @customer.badge, :from => "Customer"
  fill_in "Amount", :with => "127.00"
  fill_in "Description", :with => "awesome payment"
end
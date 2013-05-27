Given /^I am a customer$/ do
  @customer = Fabricate(:customer)
end

Given /^I am viewing the customers login page$/ do
  visit new_customer_session_path
end

Given /^I am viewing my dashboard$/ do
  step "I log in"
  visit customer_dashboard_path
end

When /^I log in$/ do
  step "I am a customer"
  step "I am viewing the customers login page"
  step "I fill in my credentials"
end

When /^I fill in my credentials$/ do
  login_as @customer
end

When /^I fill in invalid credentials$/ do
  fill_in "customer_email", with: @customer.email
  fill_in "customer_password", with: @customer.password * 2
  click_button "Login"
end

When /^I click Logout$/ do
  click_link "Logout"
end

Then /^I should be logged out$/ do
  page.should_not have_link "Login"
end

Then /^I should be viewing my profile page$/ do
  current_path.should eq customer_root_path
end

Then /^I should be viewing the home page$/ do
  current_path.should eq root_path
end

Then /^I should be viewing the customers login page$/ do
  current_path.should eq new_customer_session_path
end

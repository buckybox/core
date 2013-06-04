Given /^I am a (.*)? (.*)$/ do |status, user_type|
  raise "Invalid status" unless status.in? ["", "logged in"]

  @current_user = Fabricate(user_type)
  step "I log in" if status == "logged in"
end

Given /^I am viewing the customers login page$/ do
  visit new_customer_session_path
end

Given /^I am viewing my dashboard$/ do
  step "I am a logged in customer"
  visit customer_dashboard_path
end

When /^I fill in invalid credentials$/ do
  fill_in "customer_email", with: @current_user.email
  fill_in "customer_password", with: @current_user.password * 2
  click_button "Login"
end

Then /^I should be viewing my profile page$/ do
  current_path.should eq customer_root_path
end

Then /^I should have an order$/ do
  pending
  page.should have_selector ".customer-order"
end

Then /^I should be viewing the home page$/ do
  current_path.should eq root_path
end

Then /^I should be viewing the customers login page$/ do
  current_path.should eq new_customer_session_path
end

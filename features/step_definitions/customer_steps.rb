Given /^I am a customer/ do
  distributor = Fabricate(:distributor_with_everything)
  customer = distributor.customers.last
  customer.password = "Let me in!"
  customer.save!

  login_as customer
end

Given /^I am viewing the customers login page$/ do
  visit new_customer_session_path
end

Given /^I am viewing my dashboard$/ do
  visit customer_dashboard_path
end

When /^I fill in invalid credentials$/ do
  visit new_customer_session_path
  fill_in "customer_email", with: 'invalid'
  fill_in "customer_password", with: 'credentials'
  click_button "Login"
end

Then /^I should be viewing my profile page$/ do
  current_path.should eq customer_root_path
end

Then /^I should have an order$/ do
  page.should have_selector ".customer-order"
end

Then /^I should be viewing the home page$/ do
  current_path.should eq root_path
end

Then /^I should be viewing the customers login page$/ do
  current_path.should eq new_customer_session_path
end

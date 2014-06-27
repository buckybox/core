Given /^I am a customer$/ do
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

Then /^I should have an order$/ do
  page.should have_selector ".customer-order"
end

Then /^I should be viewing the home page$/ do
  current_path.should eq(root_path)
end

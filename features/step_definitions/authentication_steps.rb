Given /^I am viewing the (.*) login page$/ do |auth_type|
  visit send("new_#{auth_type}_session_path")
end

When /^I fill in valid (.*) credentials$/ do |auth_type|
  auth_object = send("create_#{auth_type}")
  login_with(auth_object.email, auth_object.password, auth_type)
end

When /^I fill in invalid (.*) credentials$/ do |auth_type|
  login_with("invalid", "credentials", auth_type)
end

Then /^I should be viewing the (.*) home page$/ do |auth_type|
  expected_path = send("#{auth_type}_root_path")
  current_path.should eq(expected_path)
end

Then /^I should be viewing the (.*) login page$/ do |auth_type|
  current_path.should eq(send("new_#{auth_type}_session_path"))
end

Then /^I should be viewing the distributor customer list page$/ do
  current_path.should eq(send("distributor_customers_path"))
end

Then /^I should be viewing the webstore$/ do
  distributor = Distributor.last
  expected_path = "/webstore/#{distributor.parameter_name}"
  current_path.should eq(expected_path)
end 

Given /^I am logged in as a (.*)$/ do |auth_type|
  step "I am viewing the #{auth_type} login page"
  step "I fill in valid #{auth_type} credentials"
end

When /^I log out of the admin section$/ do
  click_link "logout"
end

When /^I log out of the distributor section$/ do
  find("#user-nav .distributor-name").click
  click_link "logout"
end

When /^I log out of the customer section$/ do
  click_link "Logout"
end

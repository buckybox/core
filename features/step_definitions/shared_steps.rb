Given(/^I am unauthenticated$/) do
  find("#user-nav .distributor-name").click
  step "I log out"
  expect(page).to have_button("Login")
end

When(/^I log out$/) do
  click_link "logout" if page.has_link? "logout"
  page.should have_button "Login"
end

Then(/^I should be logged out$/) do
  expect(page).to_not have_link("Login")
end

Then(/^I should not see a message$/) do
  %w(success failure).each do |type|
    step "I should not see a #{type} message"
  end
end

Then(/^I should not see a.? (.*) message$/) do |type|
  expect(page).to_not have_selector("div.alert-#{type}")
end

Then(/^I should see a.? (.*) message with "(.*)"$/) do |type, message|
  expect(page).to have_selector("div.alert-#{type}", text: message)
end

Given(/^I click on "(.*?)"$/) do |link_name|
  click_on link_name
end

Then(/^I should see an? "(.*?)" field$/) do |field_name|
  expect(page.has_field? field_name).to be_true
end

Then(/^I should not see an? "(.*?)" field$/) do |field_name|
  expect(page.has_field? field_name).to be_false
end

When(/^I submit the form without an? "(.*?)"$/) do |field_name|
  fill_in field_name, with: ""
  step 'I click on "Update"'
end

When(/^I submit the form with an? "(.*?)" of "(.*?)"$/) do |field_name, value|
  fill_in field_name, with: value
  step 'I click on "Update"'
end

Then(/^I should get an error "(.*?)"$/) do |error_message|
  expect(page).to have_content error_message
end

Then(/^I should not get an error "(.*?)"$/) do |error_message|
  expect(page).to_not have_content error_message
end

Given "I am unauthenticated" do
  find("#user-nav .distributor-name").click
  step "I log out"
  page.should have_button "Login"
end

When /^I log out$/ do
  click_link "logout" if page.has_link? "logout"
end

Then /^I should be logged out$/ do
  page.should_not have_link "Login"
end

Then "I should not see a message" do
  %w(success failure).each do |type|
    step "I should not see a #{type} message"
  end
end

Then /^I should not see a.? (.*) message$/ do |type|
  page.should_not have_selector "div.alert-#{type}"
end

Then /^I should see a.? (.*) message with "(.*)"$/ do |type, message|
  page.should have_selector "div.alert-#{type}", text: message
end


Given /^I am unauthenticated$/ do
  find("#user-nav .distributor-name").click
  click_link "logout" if page.has_link? "logout"
  page.should have_button "Login"
end

Then /^I should not see a message$/ do
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


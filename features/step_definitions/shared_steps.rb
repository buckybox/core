Given "I am unauthenticated" do
  if @current_user_logged_in # FIXME brittle
    puts "Logging off"
    visit public_send("destroy_#{user_type(@current_user)}_session_path")
    @current_user_logged_in = false
  end
end

Given /^I am a customer$/ do
  @current_user = Fabricate(:customer)
end

When /^I log in$/ do
  login_as @current_user
end

When /^I log out$/ do
  click_link "Logout"
end

Then /^I should be logged out$/ do
  # @current_user_logged_in.should be_false
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


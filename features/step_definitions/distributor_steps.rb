Given /^A distributor is in the system$/ do
  step "I am a distributor"
end

Given /^I am a distributor$/ do
  @current_user = Fabricate(:distributor_with_webstore)
  step "I have an existing customer"
end

When /^I log in as a distributor$/ do
  login_as @current_user
end

Given /^I am on the dashboard$/ do
  visit "/"
end

Given /^a distributor looking at their dashboard$/ do
  step "I am a distributor"
  step "I am on the dashboard"
end

Given /^I am a distributor$/ do
  @distributor = Fabricate(:distributor)
  step "I have an existing customer"
  login_as(@distributor)
end

Given /^I am on the dashboard$/ do
  visit "/"
end

Given /^a distributor looking at their dashboard$/ do
  step "I am a distributor"
  step "I am on the dashboard"
end

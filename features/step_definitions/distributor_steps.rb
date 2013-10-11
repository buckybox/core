Given /^A distributor is in the system$/ do
  step "I am logged in as a distributor"
end

Given /^I am on the dashboard$/ do
  visit distributor_customers_path
end

Then /^I should be viewing the dashboard$/ do
  current_path.should eq(distributor_customers_path)
end

Given /^a distributor looking at their dashboard$/ do
  step "I am logged in as a distributor"
  step "I am on the dashboard"
end

Given /^I am viewing my dashboard$/ do
  visit customer_dashboard_path
end

Then /^I should have an order$/ do
  page.should have_selector ".customer-order"
end

Then /^I should be viewing the home page$/ do
  current_path.should eq(root_path)
end

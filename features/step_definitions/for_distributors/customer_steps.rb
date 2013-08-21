Given /^I am viewing the customers page$/ do
  visit distributor_customers_path
  step "I dismiss the intro screen"
end

Given /^I am viewing an existing customer$/ do
  step "I am viewing the customers page"
  find(".customer-id").click
end

When /^I add a new customer$/ do
  click_link "Create a new customer"
  step "I fill in valid customer details"
  click_button "Create Customer"
  Customer.find_by_email("bilbo@baggins.com").should_not be_nil
end

When /^I fill in valid customer details$/ do
  fill_in "Email", with: "bilbo@baggins.com"
  fill_in "First name", with: "Bilbo"
  fill_in "Address 1", with: "1 Bag End"
  fill_in "Suburb", with: "Hobbiton"
  fill_in "City", with: "The Water"
end

Then /^I should be viewing the customer$/ do
  page.should have_content "Bilbo"
end

Then /^The customer should be on the customers index page$/ do
  visit distributor_customers_path
  within('#customers') do
    page.should have_content('Bilbo')
  end
end

When /^I edit the customer's profile$/ do
  step "I dismiss the intro screen"
  click_link "edit profile"
end

When /^I change the customer's first name to "(.*?)"$/ do |name|
  fill_in "First name", with: name
  click_button "Update"
end

Then /^The customer's page should show the name "(.*?)"$/ do |name|
  page.should have_css('.customer-name', text: name)
end

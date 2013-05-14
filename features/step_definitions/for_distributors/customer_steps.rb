Given /^I am viewing the customers page$/ do
  visit distributor_customers_path
end

Given /^I am viewing an existing customer$/ do
  @customer.should_not be_nil
  visit distributor_customer_path(@customer)
end

When /^I add a new customer$/ do
  click_link "Create a new customer"
  step "I fill in valid customer details"
  click_button "Create Customer"
  @customer = Customer.find_by_email("bilbo@baggins.com")
  @customer.should_not be_nil
end

When /^I fill in valid customer details$/ do
  fill_in "Email", with: "bilbo@baggins.com"
  fill_in "First name", with: "Bilbo"
  fill_in "Address 1", with: "1 Bag End"
  fill_in "Suburb", with: "Hobbiton"
  fill_in "City", with: "The Water"
end

Then /^I should be viewing the customer$/ do
  current_path.should == distributor_customer_path(@customer)
end

Then /^The customer should be on the customers index page$/ do
  visit distributor_customers_path
  within('#customers') do
    page.should have_content('Bilbo')
  end
end

Given /^I have an existing customer$/ do
  @distributor.should_not be_nil
  @customer = Fabricate(:customer, distributor: @distributor)
end

When /^I edit the customer's profile$/ do
  click_link "edit profile"
end

When /^I change the customer's first name to "(.*?)"$/ do |name|
  fill_in "First name", with: name
  click_button "Update"
end

Then /^The customer's page should show the name "(.*?)"$/ do |name|
  visit distributor_customer_path(@customer)
  page.should have_css('.customer-name', text: name)
end

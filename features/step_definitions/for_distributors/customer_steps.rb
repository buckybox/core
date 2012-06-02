Given /^I am viewing the customers page$/ do
  visit distributor_customers_path
end

When /^I add a new customer$/ do
  click_link "New Customer"
  step "I fill in valid customer details"
  click_button "Create Customer"
  @customer = Customer.find_by_email("bilbo@baggins.com")
  @customer.should_not be_nil
end

When /^I fill in valid customer details$/ do
  fill_in "Email", :with => "bilbo@baggins.com"
  fill_in "First name", :with => "Bilbo"
  fill_in "Address 1", :with => "1 Bag End"
  fill_in "Suburb", :with => "Hobbiton"
  fill_in "City", :with => "The Water"
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
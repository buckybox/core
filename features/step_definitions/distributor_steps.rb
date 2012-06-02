def login_as(user)
  visit "/distributors/sign_in"
  fill_in "Email", :with => @distributor.email
  fill_in "Password", :with => 'password'
  click_button "Sign in"
end

Given /^I am a distributor$/ do
  @distributor = Fabricate(:distributor, :password => "password", :password_confirmation => 'password')
  @customer = Fabricate(:customer, :distributor => @distributor)
  login_as(@distributor)
end

Given /^I am on the dashboard$/ do
  visit "/"
end

Given /^a distributor looking at their dashboard$/ do
  step "I am a distributor"
  step "I am on the dashboard"
end

When /^I submit valid payment details$/ do
  select "##{@customer.id} #{@customer.name}", :from => "Customer"
  fill_in "Amount", :with => "127.00"
  fill_in "Description", :with => "awesome payment"
  click_button "Create Payment"
end

Then /^the payment is recorded against that customer$/ do
  visit distributor_customer_path(@customer)
  save_and_open_page
  within_table('transactions') do
    page.should have_content('$127.00')
  end
end

Then /^the customer balance increases by the payment amount$/ do
  page.should have_css('#account-balance', :text => '$127.00')
end
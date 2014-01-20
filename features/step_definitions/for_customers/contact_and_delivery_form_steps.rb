Given(/^I am a customer for a distributor that does not collect (.*?)$/) do |attribute|
  distributor = Fabricate(:distributor_with_everything, collect_options(attribute, false))
  customer_login_with_distributor(distributor)
end

Given(/^I am a customer for a distributor that collects (.*?)$/) do |attribute|
  distributor = Fabricate(:distributor_with_everything, collect_options(attribute))
  customer_login_with_distributor(distributor)
end

Given(/^I am a customer for a distributor that does not require (.*?)$/) do |attribute|
  distributor = Fabricate(:distributor_with_everything, require_options(attribute, false))
  customer_login_with_distributor(distributor)
end

Given(/^I am a customer for a distributor that requires (.*?)$/) do |attribute|
  distributor = Fabricate(:distributor_with_everything, require_options(attribute))
  customer_login_with_distributor(distributor)
end

When(/^I submit the form without a phone number$/) do
  pending "Works when changing an existing phone number but not a new one. Fix with form object."
  fill_in "Mobile phone", with: ""
  fill_in "Home phone", with: ""
  fill_in "Work phone", with: ""
  step 'I click on "Update"'
end

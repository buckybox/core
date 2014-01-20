Given(/^I am a customer for a distributor that does not collect (.*?)$/) do |attribute|
  distributor = Fabricate(:distributor_with_everything, collect_options(attribute, false))
  customer_login_with_distributor(distributor)
end

Given(/^I am a customer for a distributor that collects (.*?)$/) do |attribute|
  distributor = Fabricate(:distributor_with_everything, collect_options(attribute))
  customer_login_with_distributor(distributor)
end

Given(/^I am a customer for a distributor that does not require (.*?)$/) do
  distributor = Fabricate(:distributor_with_everything, require_options(attribute, false))
  customer_login_with_distributor(distributor)
end

Given(/^I am a customer for a distributor that requires (.*?)$/) do
  distributor = Fabricate(:distributor_with_everything, require_options(attribute))
  customer_login_with_distributor(distributor)
end

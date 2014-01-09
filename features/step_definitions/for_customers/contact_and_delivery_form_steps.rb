Given(/^I am a customer for a distributor that collects (.*?)$/) do |attribute|
  distributor = Fabricate(:distributor_with_everything, collect_options(attribute))

  customer = distributor.customers.last
  customer.password = "Let me in!"
  customer.save!

  login_as customer
end

Given(/^I am a customer for a distributor that does not collect (.*?)$/) do |attribute|
  distributor = Fabricate(:distributor_with_everything, collect_options(attribute, false))

  customer = distributor.customers.last
  customer.password = "Let me in!"
  customer.save!

  login_as customer
end

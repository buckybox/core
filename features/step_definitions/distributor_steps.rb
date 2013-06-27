Given /^A distributor is in the system$/ do
  step "I am a distributor"
end

Given /^I am a distributor$/ do
  distributor = Fabricate(:distributor_with_everything)
  distributor.active_webstore = true
  distributor.save!
  login_as distributor

  step "I dismiss the intro screen"
end

Given /^I am on the dashboard$/ do
  visit distributor_customers_path
end

Then /^I should be viewing the dashboard$/ do
  current_path.should eq distributor_customers_path
end

Given /^a distributor looking at their dashboard$/ do
  step "I am a distributor"
  step "I am on the dashboard"
end

When "I dismiss the intro screen" do
  sleep 1 # ugly but the modal takes its time to show up sometimes
  find("#close-intro-tour").click if page.has_css? "#close-intro-tour"
end


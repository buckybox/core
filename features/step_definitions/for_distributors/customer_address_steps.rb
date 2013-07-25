Given(/^I have notify address option turned on$/) do
  @distributor.update_attribute(:notify_address_change, true)
end

Then(/^I should not receive a notification of the address change$/) do
  page.should_not have_content "Customer changed address"
end

When(/^I edit the customer's address$/) do
  click_link "edit delivery details"
  fill_in "Suburb", with: "this better not match the previous suburb"
  click_button "Update"
end

Then(/^The distributor should receive a notification of the address change$/) do
  page.has_content?("Customer changed address")
end

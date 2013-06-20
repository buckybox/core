When "I dismiss the intro screen" do
  click_button "close-intro-tour"
  sleep 0.5 # ugly but the modal takes its time to fade out sometimes
end

When "I select all my customers in the list" do
  find("#select_all").click
end

When "I open the emailer" do
  find('a[href="#distributor_customers_send_email"]').click

  # assert that the modal is visible
  page.should have_selector("#distributor_customers_send_email")
end

When /^I fill in the (subject|body) with "(.*)"$/ do |field, content|
  fill_in "email_template_#{field}", with: content
end

Then "I should be able to save it as a new template" do
  find('#distributor_customers_send_email .composer [data-toggle="dropdown"]').click
  find('#distributor_customers_send_email a[data-link-action="save"]').click
end


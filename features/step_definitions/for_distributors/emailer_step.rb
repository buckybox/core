When "I dismiss the intro screen" do
  sleep 1 # ugly but the modal takes its time to show up sometimes
  find("#close-intro-tour").click if page.has_css? "#close-intro-tour"
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

Then "I should be able to send an email" do
  click_button "Send"
end


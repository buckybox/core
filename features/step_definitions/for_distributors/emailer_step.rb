When "I select all my customers in the list" do
  find("#select_all").click
end

When "I open the emailer" do
  find('a[href="#distributor_send_email"]').click

  # assert that the modal is visible
  page.should have_selector("#distributor_send_email")
end

When /^I fill in the (subject|body) with "(.*)"$/ do |field, content|
  fill_in "email_template_#{field}", with: content
end

Then "I should be able to send an email" do
    # we need to inhibit the mailer otherwise DJ may try to send it later on
    # after DatabaseCleaner wiped the recipient customer - will would fail
    CustomerMailer.should_receive(:email_template).at_least(:once).and_return(double(deliver: nil))

    click_button "Send"
    sleep 10 # wait for the page reload from JS
    step "I should be viewing the dashboard"
end


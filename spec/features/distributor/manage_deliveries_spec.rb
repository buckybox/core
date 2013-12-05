require "spec_helper"

feature "Manage deliveries", js: true do
  scenario "marks a delivery as delivered and paid" do
    # setup
    @distributor = Fabricate(:distributor_with_everything)
    simulate_distributor_sign_in
    customer = @distributor.customers.first
    order = Fabricate(:order, account: customer.account)
    @distributor.generate_required_daily_lists

    # go to deliveries page
    visit distributor_deliveries_path

    # go to the first yellow day
    find(:xpath, '//a[@title="pending deliveries"]').click
    click_link order.delivery_service.name

    # test "Mark as delivered" button
    page.should_not have_selector(".state-label.status-delivered")
    find(:xpath, '//button[@id="delivered"]').click
    page.should have_selector(".state-label.status-delivered")

    # test "Apply cash on delivery"
    page.should_not have_selector(".paid-label.paid")
    find(:xpath, '//button[@id="delivered"]/following-sibling::button').click # open dropdown
    click_link "Apply cash on delivery"
    page.should have_selector(".paid-label.paid")

    # reload the page and make sure the AJAX requests went through
    visit current_path
    page.should have_selector(".state-label.status-delivered")
    page.should have_selector(".paid-label.paid")
  end
end

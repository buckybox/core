require "spec_helper"

feature "Manage an order", js: true do
  scenario "browses to the dashboard" do
    @distributor = Fabricate(:distributor)
    @customer = Fabricate(:customer, distributor: @distributor)
    simulate_customer_sign_in

    visit customer_root_path
    expect(page).to have_content @customer.name
  end

  scenario "sets a pause and resume date for an order" do
    @distributor = Fabricate(:distributor)
    @customer = Fabricate(:customer, distributor: @distributor)
    order = Fabricate(:order, customer: @customer)

    # customer facing UI
    simulate_customer_sign_in
    visit customer_root_path

    click_link "pause"
    click_button "pause"
    expect(page).to have_content "pausing starts"

    click_link "until further notice"
    click_button "resume"
    expect(page).to have_content "resuming deliveries on"

    find(".pause > .resulting-link > a").click
    click_link "remove"
    expect(page).to have_link "pause"
    expect(page).not_to have_content "pausing starts"
    expect(page).not_to have_content "resuming deliveries on"

    # distributor facing UI
    simulate_distributor_sign_in
    visit distributor_customer_path(id: @customer.id)
    expect(@customer.activities.size).to eq(3)
    expect(page).to have_content "RECENT ACTIVITY"
    expect(page).to have_content "less than a minute ago - #{@customer.name} paused their order of #{order.box.name}"
    expect(page).to have_content "less than a minute ago - #{@customer.name} updated their order of #{order.box.name} to resume on"
    expect(page).to have_content "less than a minute ago - #{@customer.name} unpaused their order of #{order.box.name}"
  end
end

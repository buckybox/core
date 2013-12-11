require "spec_helper"

feature "Manage an order", js: true do
  scenario "browses to the dashboard" do
    @distributor = Fabricate(:distributor)
    @customer = Fabricate(:customer, distributor: @distributor)
    simulate_customer_sign_in

    visit customer_root_path
    page.should have_content @customer.name
  end
end

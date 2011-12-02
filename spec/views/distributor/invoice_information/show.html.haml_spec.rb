require 'spec_helper'

describe "distributor_invoice_information/show.html.haml" do
  before(:each) do
    @invoice_information = assign(:invoice_information, stub_model(Distributor::InvoiceInformation,
      :distributor => nil,
      :gst_number => "Gst Number",
      :billing_address_1 => "Billing Address 1",
      :billing_address_2 => "Billing Address 2",
      :billing_suburb => "Billing Suburb",
      :billing_city => "Billing City",
      :billing_postcode => "Billing Postcode"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Gst Number/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Billing Address 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Billing Address 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Billing Suburb/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Billing City/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Billing Postcode/)
  end
end

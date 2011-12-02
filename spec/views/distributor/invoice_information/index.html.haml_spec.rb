require 'spec_helper'

describe "distributor_invoice_information/index.html.haml" do
  before(:each) do
    assign(:distributor_invoice_information, [
      stub_model(Distributor::InvoiceInformation,
        :distributor => nil,
        :gst_number => "Gst Number",
        :billing_address_1 => "Billing Address 1",
        :billing_address_2 => "Billing Address 2",
        :billing_suburb => "Billing Suburb",
        :billing_city => "Billing City",
        :billing_postcode => "Billing Postcode"
      ),
      stub_model(Distributor::InvoiceInformation,
        :distributor => nil,
        :gst_number => "Gst Number",
        :billing_address_1 => "Billing Address 1",
        :billing_address_2 => "Billing Address 2",
        :billing_suburb => "Billing Suburb",
        :billing_city => "Billing City",
        :billing_postcode => "Billing Postcode"
      )
    ])
  end

  it "renders a list of distributor_invoice_information" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Gst Number".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Billing Address 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Billing Address 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Billing Suburb".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Billing City".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Billing Postcode".to_s, :count => 2
  end
end

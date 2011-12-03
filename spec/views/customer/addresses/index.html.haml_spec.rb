require 'spec_helper'

describe "customer_addresses/index.html.haml" do
  before(:each) do
    assign(:customer_addresses, [
      stub_model(Customer::Address,
        :customer => nil,
        :address_1 => "Address 1",
        :address_2 => "Address 2",
        :suburb => "Suburb",
        :city => "City",
        :postcode => "Postcode",
        :delivery_note => "MyText"
      ),
      stub_model(Customer::Address,
        :customer => nil,
        :address_1 => "Address 1",
        :address_2 => "Address 2",
        :suburb => "Suburb",
        :city => "City",
        :postcode => "Postcode",
        :delivery_note => "MyText"
      )
    ])
  end

  it "renders a list of customer_addresses" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Address 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Address 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Suburb".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "City".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Postcode".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end

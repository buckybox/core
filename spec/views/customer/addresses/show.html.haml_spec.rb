require 'spec_helper'

describe "customer_addresses/show.html.haml" do
  before(:each) do
    @address = assign(:address, stub_model(Customer::Address,
      :customer => nil,
      :address_1 => "Address 1",
      :address_2 => "Address 2",
      :suburb => "Suburb",
      :city => "City",
      :postcode => "Postcode",
      :delivery_note => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Address 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Address 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Suburb/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/City/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Postcode/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/MyText/)
  end
end

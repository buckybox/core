require 'spec_helper'

describe "customer_addresses/edit.html.haml" do
  before(:each) do
    @address = assign(:address, stub_model(Customer::Address,
      :customer => nil,
      :address_1 => "MyString",
      :address_2 => "MyString",
      :suburb => "MyString",
      :city => "MyString",
      :postcode => "MyString",
      :delivery_note => "MyText"
    ))
  end

  it "renders the edit address form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => customer_addresses_path(@address), :method => "post" do
      assert_select "input#address_customer", :name => "address[customer]"
      assert_select "input#address_address_1", :name => "address[address_1]"
      assert_select "input#address_address_2", :name => "address[address_2]"
      assert_select "input#address_suburb", :name => "address[suburb]"
      assert_select "input#address_city", :name => "address[city]"
      assert_select "input#address_postcode", :name => "address[postcode]"
      assert_select "textarea#address_delivery_note", :name => "address[delivery_note]"
    end
  end
end

require 'spec_helper'

describe "distributor_invoice_information/edit.html.haml" do
  before(:each) do
    @invoice_information = assign(:invoice_information, stub_model(Distributor::InvoiceInformation,
      :distributor => nil,
      :gst_number => "MyString",
      :billing_address_1 => "MyString",
      :billing_address_2 => "MyString",
      :billing_suburb => "MyString",
      :billing_city => "MyString",
      :billing_postcode => "MyString"
    ))
  end

  it "renders the edit invoice_information form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => distributor_invoice_information_index_path(@invoice_information), :method => "post" do
      assert_select "input#invoice_information_distributor", :name => "invoice_information[distributor]"
      assert_select "input#invoice_information_gst_number", :name => "invoice_information[gst_number]"
      assert_select "input#invoice_information_billing_address_1", :name => "invoice_information[billing_address_1]"
      assert_select "input#invoice_information_billing_address_2", :name => "invoice_information[billing_address_2]"
      assert_select "input#invoice_information_billing_suburb", :name => "invoice_information[billing_suburb]"
      assert_select "input#invoice_information_billing_city", :name => "invoice_information[billing_city]"
      assert_select "input#invoice_information_billing_postcode", :name => "invoice_information[billing_postcode]"
    end
  end
end

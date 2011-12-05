require 'spec_helper'

describe "distributor_payments/edit.html.haml" do
  before(:each) do
    @payment = assign(:payment, stub_model(Distributor::Payment,
      :distributor => nil,
      :customer => nil,
      :amount_cents => 1,
      :currency => "MyString",
      :kind => "MyString",
      :description => "MyText"
    ))
  end

  it "renders the edit payment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => distributor_payments_path(@payment), :method => "post" do
      assert_select "input#payment_distributor", :name => "payment[distributor]"
      assert_select "input#payment_customer", :name => "payment[customer]"
      assert_select "input#payment_amount_cents", :name => "payment[amount_cents]"
      assert_select "input#payment_currency", :name => "payment[currency]"
      assert_select "input#payment_kind", :name => "payment[kind]"
      assert_select "textarea#payment_description", :name => "payment[description]"
    end
  end
end

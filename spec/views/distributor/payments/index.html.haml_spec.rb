require 'spec_helper'

describe "distributor_payments/index.html.haml" do
  before(:each) do
    assign(:distributor_payments, [
      stub_model(Distributor::Payment,
        :distributor => nil,
        :customer => nil,
        :amount_cents => 1,
        :currency => "Currency",
        :kind => "Kind",
        :description => "MyText"
      ),
      stub_model(Distributor::Payment,
        :distributor => nil,
        :customer => nil,
        :amount_cents => 1,
        :currency => "Currency",
        :kind => "Kind",
        :description => "MyText"
      )
    ])
  end

  it "renders a list of distributor_payments" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Currency".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Kind".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end

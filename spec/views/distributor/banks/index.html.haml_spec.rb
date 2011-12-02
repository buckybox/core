require 'spec_helper'

describe "distributor_banks/index.html.haml" do
  before(:each) do
    assign(:distributor_banks, [
      stub_model(Distributor::Bank,
        :distributor => nil,
        :name => "Name",
        :account_name => "Account Name",
        :account_number => "Account Number",
        :customer_message => "Customer Message"
      ),
      stub_model(Distributor::Bank,
        :distributor => nil,
        :name => "Name",
        :account_name => "Account Name",
        :account_number => "Account Number",
        :customer_message => "Customer Message"
      )
    ])
  end

  it "renders a list of distributor_banks" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Account Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Account Number".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Customer Message".to_s, :count => 2
  end
end

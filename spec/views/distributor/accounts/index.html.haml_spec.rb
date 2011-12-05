require 'spec_helper'

describe "distributor_accounts/index.html.haml" do
  before(:each) do
    assign(:distributor_accounts, [
      stub_model(Distributor::Account,
        :distributor => nil,
        :customer => nil,
        :balance_cents => 1,
        :currenty => "Currenty"
      ),
      stub_model(Distributor::Account,
        :distributor => nil,
        :customer => nil,
        :balance_cents => 1,
        :currenty => "Currenty"
      )
    ])
  end

  it "renders a list of distributor_accounts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Currenty".to_s, :count => 2
  end
end

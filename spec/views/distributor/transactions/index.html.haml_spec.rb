require 'spec_helper'

describe "distributor_transactions/index.html.haml" do
  before(:each) do
    assign(:distributor_transactions, [
      stub_model(Distributor::Transaction,
        :distributor => nil,
        :customer => nil,
        :transactionable => nil,
        :amount_cents => 1,
        :currency => "Currency",
        :description => "MyText"
      ),
      stub_model(Distributor::Transaction,
        :distributor => nil,
        :customer => nil,
        :transactionable => nil,
        :amount_cents => 1,
        :currency => "Currency",
        :description => "MyText"
      )
    ])
  end

  it "renders a list of distributor_transactions" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Currency".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end

require 'spec_helper'

describe "distributor_orders/index.html.haml" do
  before(:each) do
    assign(:distributor_orders, [
      stub_model(Distributor::Order,
        :distributor => nil,
        :box => nil,
        :customer => nil,
        :quantity => 1,
        :likes => "MyText",
        :dislikes => "MyText"
      ),
      stub_model(Distributor::Order,
        :distributor => nil,
        :box => nil,
        :customer => nil,
        :quantity => 1,
        :likes => "MyText",
        :dislikes => "MyText"
      )
    ])
  end

  it "renders a list of distributor_orders" do
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
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end

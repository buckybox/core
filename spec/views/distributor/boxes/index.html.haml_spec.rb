require 'spec_helper'

describe "distributor_boxes/index.html.haml" do
  before(:each) do
    assign(:distributor_boxes, [
      stub_model(Distributor::Box,
        :name => "Name",
        :description => "MyText",
        :likes => false,
        :dislikes => false,
        :price_cents => 1,
        :currency => "Currency",
        :available_single => false,
        :available_weekly => false,
        :available_fourtnightly => false
      ),
      stub_model(Distributor::Box,
        :name => "Name",
        :description => "MyText",
        :likes => false,
        :dislikes => false,
        :price_cents => 1,
        :currency => "Currency",
        :available_single => false,
        :available_weekly => false,
        :available_fourtnightly => false
      )
    ])
  end

  it "renders a list of distributor_boxes" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Currency".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
  end
end

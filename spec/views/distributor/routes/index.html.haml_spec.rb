require 'spec_helper'

describe "distributor_routes/index.html.haml" do
  before(:each) do
    assign(:distributor_routes, [
      stub_model(Distributor::Route,
        :distributor => nil,
        :name => "Name",
        :monday => false,
        :tuesday => false,
        :wednesday => false,
        :thursday => false,
        :friday => false,
        :saturday => false,
        :sunday => false
      ),
      stub_model(Distributor::Route,
        :distributor => nil,
        :name => "Name",
        :monday => false,
        :tuesday => false,
        :wednesday => false,
        :thursday => false,
        :friday => false,
        :saturday => false,
        :sunday => false
      )
    ])
  end

  it "renders a list of distributor_routes" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => nil.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => false.to_s, :count => 2
  end
end

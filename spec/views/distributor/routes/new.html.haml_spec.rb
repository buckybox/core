require 'spec_helper'

describe "distributor_routes/new.html.haml" do
  before(:each) do
    assign(:route, stub_model(Distributor::Route,
      :distributor => nil,
      :name => "MyString",
      :monday => false,
      :tuesday => false,
      :wednesday => false,
      :thursday => false,
      :friday => false,
      :saturday => false,
      :sunday => false
    ).as_new_record)
  end

  it "renders new route form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => distributor_routes_path, :method => "post" do
      assert_select "input#route_distributor", :name => "route[distributor]"
      assert_select "input#route_name", :name => "route[name]"
      assert_select "input#route_monday", :name => "route[monday]"
      assert_select "input#route_tuesday", :name => "route[tuesday]"
      assert_select "input#route_wednesday", :name => "route[wednesday]"
      assert_select "input#route_thursday", :name => "route[thursday]"
      assert_select "input#route_friday", :name => "route[friday]"
      assert_select "input#route_saturday", :name => "route[saturday]"
      assert_select "input#route_sunday", :name => "route[sunday]"
    end
  end
end

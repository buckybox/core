require 'spec_helper'

describe "distributor_boxes/new.html.haml" do
  before(:each) do
    assign(:box, stub_model(Distributor::Box,
      :name => "MyString",
      :description => "MyText",
      :likes => false,
      :dislikes => false,
      :price_cents => 1,
      :currency => "MyString",
      :available_single => false,
      :available_weekly => false,
      :available_fourtnightly => false
    ).as_new_record)
  end

  it "renders new box form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => distributor_boxes_path, :method => "post" do
      assert_select "input#box_name", :name => "box[name]"
      assert_select "textarea#box_description", :name => "box[description]"
      assert_select "input#box_likes", :name => "box[likes]"
      assert_select "input#box_dislikes", :name => "box[dislikes]"
      assert_select "input#box_price_cents", :name => "box[price_cents]"
      assert_select "input#box_currency", :name => "box[currency]"
      assert_select "input#box_available_single", :name => "box[available_single]"
      assert_select "input#box_available_weekly", :name => "box[available_weekly]"
      assert_select "input#box_available_fourtnightly", :name => "box[available_fourtnightly]"
    end
  end
end

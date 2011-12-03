require 'spec_helper'

describe "distributor_orders/edit.html.haml" do
  before(:each) do
    @order = assign(:order, stub_model(Distributor::Order,
      :distributor => nil,
      :box => nil,
      :customer => nil,
      :quantity => 1,
      :likes => "MyText",
      :dislikes => "MyText"
    ))
  end

  it "renders the edit order form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => distributor_orders_path(@order), :method => "post" do
      assert_select "input#order_distributor", :name => "order[distributor]"
      assert_select "input#order_box", :name => "order[box]"
      assert_select "input#order_customer", :name => "order[customer]"
      assert_select "input#order_quantity", :name => "order[quantity]"
      assert_select "textarea#order_likes", :name => "order[likes]"
      assert_select "textarea#order_dislikes", :name => "order[dislikes]"
    end
  end
end

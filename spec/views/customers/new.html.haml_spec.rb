require 'spec_helper'

describe "customers/new.html.haml" do
  before(:each) do
    assign(:customer, stub_model(Customer,
      :name => "MyString",
      :email => "MyString",
      :phone => "MyString"
    ).as_new_record)
  end

  it "renders new customer form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => customers_path, :method => "post" do
      assert_select "input#customer_name", :name => "customer[name]"
      assert_select "input#customer_email", :name => "customer[email]"
      assert_select "input#customer_phone", :name => "customer[phone]"
    end
  end
end

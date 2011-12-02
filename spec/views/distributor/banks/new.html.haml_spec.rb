require 'spec_helper'

describe "distributor_banks/new.html.haml" do
  before(:each) do
    assign(:bank, stub_model(Distributor::Bank,
      :distributor => nil,
      :name => "MyString",
      :account_name => "MyString",
      :account_number => "MyString",
      :customer_message => "MyString"
    ).as_new_record)
  end

  it "renders new bank form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => distributor_banks_path, :method => "post" do
      assert_select "input#bank_distributor", :name => "bank[distributor]"
      assert_select "input#bank_name", :name => "bank[name]"
      assert_select "input#bank_account_name", :name => "bank[account_name]"
      assert_select "input#bank_account_number", :name => "bank[account_number]"
      assert_select "input#bank_customer_message", :name => "bank[customer_message]"
    end
  end
end

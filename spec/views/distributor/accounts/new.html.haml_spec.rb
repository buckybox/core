require 'spec_helper'

describe "distributor_accounts/new.html.haml" do
  before(:each) do
    assign(:account, stub_model(Distributor::Account,
      :distributor => nil,
      :customer => nil,
      :balance_cents => 1,
      :currenty => "MyString"
    ).as_new_record)
  end

  it "renders new account form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => distributor_accounts_path, :method => "post" do
      assert_select "input#account_distributor", :name => "account[distributor]"
      assert_select "input#account_customer", :name => "account[customer]"
      assert_select "input#account_balance_cents", :name => "account[balance_cents]"
      assert_select "input#account_currenty", :name => "account[currenty]"
    end
  end
end

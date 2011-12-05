require 'spec_helper'

describe "distributor_transactions/new.html.haml" do
  before(:each) do
    assign(:transaction, stub_model(Distributor::Transaction,
      :distributor => nil,
      :customer => nil,
      :transactionable => nil,
      :amount_cents => 1,
      :currency => "MyString",
      :description => "MyText"
    ).as_new_record)
  end

  it "renders new transaction form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => distributor_transactions_path, :method => "post" do
      assert_select "input#transaction_distributor", :name => "transaction[distributor]"
      assert_select "input#transaction_customer", :name => "transaction[customer]"
      assert_select "input#transaction_transactionable", :name => "transaction[transactionable]"
      assert_select "input#transaction_amount_cents", :name => "transaction[amount_cents]"
      assert_select "input#transaction_currency", :name => "transaction[currency]"
      assert_select "textarea#transaction_description", :name => "transaction[description]"
    end
  end
end

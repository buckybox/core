require 'spec_helper'

include Bucky::TransactionImports

describe Bucky::TransactionImports::Row do
  describe ".amount_match" do
    specify { Row.amount_match(0, -100).should eq(0.0)}
    specify { Row.amount_match(0, -450).should eq(0.0)}
    specify { Row.amount_match(100, -100).should eq(1.0)}
    specify { Row.amount_match(450, -450).should eq(1.0)}
    specify { Row.amount_match(149.99, -100).should eq(0.5001)}
    specify { Row.amount_match(150, -200).should eq(0.75)}
    specify { Row.amount_match(97, -100).should eq(0.97)}
    specify { Row.amount_match(150, -100).should eq(0.5)}
    specify { Row.amount_match(0, -100).should eq(0.0)}
    specify { Row.amount_match(200, -100).should eq(0.0)}
    specify { Row.amount_match(250, -100).should eq(0.0)}
    specify { Row.amount_match(350, -100).should eq(0.0)}
    specify { Row.amount_match(125, -100).should eq(0.75)}
    specify { Row.amount_match(175, -100).should eq(0.25)}
    specify { Row.amount_match(100, -100).should eq(1.00)}
    specify { Row.amount_match(100, 100).should eq(0)}
    specify { Row.amount_match(10, 2).should eq(0)}
  end

  describe ".amount_cents" do
    it "converts string to cents integer" do
      row = new_row("17.9")
      row.amount_cents.should eq 1790
    end
  end

  describe ".account_match" do
    it "matches row to customers account based on account balance and row amount" do
      row = new_row("20.01")
      customer = double("customer")
      customer.stub_chain(:account, :balance_cents).and_return(-2001)
      row.stub(:no_other_account_matches?).and_return(true)
      row.account_match(customer).should eq 1.0
    end
  end
end

def new_row(amount_string)
  Row.new("2013-06-07","test row", amount_string)
end

def mock_customer(formated_number, balance = 0.0, orders = [0.0], first_name = nil, last_name = nil)
  # Setting the id below helps identify when a test fails
  mc = mock_model(Customer, formated_number: formated_number, id: formated_number)
  mc.stub_chain(:account, :balance, :to_f).and_return(balance)
  mc.stub(:orders).and_return(orders.collect{|o| stub(Order, price: o)})
  mc.stub(:first_name).and_return(first_name) if first_name.present?
  mc.stub(:last_name).and_return(last_name) if last_name.present?
  mc
end

def real_customer(formated_number, balance = 0.0, orders = [0.0], first_name = nil, last_name = nil)
  c = Fabricate(:customer, number: formated_number.to_i)
  c.stub_chain(:account, :balance, :to_f).and_return(balance)
  c.stub(:orders).and_return(orders.collect{|o| stub(Order, price: o)})
  c.first_name = first_name unless first_name.blank?
  c.last_name = last_name unless last_name.blank?
  c
end

def mock_customer_with_history(formated_number, opts = {})
  mc = mock_customer(formated_number)
  previous_matches = opts.delete(:previous_matches)
  mc.stub(:previous_matches).and_return(previous_matches)
  mc
end

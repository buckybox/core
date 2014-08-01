require 'spec_helper'

include Bucky::TransactionImports

describe Bucky::TransactionImports::Row do
  describe ".amount_match" do
    specify { expect(Row.amount_match(0, -100)).to eq(0.0)}
    specify { expect(Row.amount_match(0, -450)).to eq(0.0)}
    specify { expect(Row.amount_match(100, -100)).to eq(1.0)}
    specify { expect(Row.amount_match(450, -450)).to eq(1.0)}
    specify { expect(Row.amount_match(149.99, -100)).to eq(0.5001)}
    specify { expect(Row.amount_match(150, -200)).to eq(0.75)}
    specify { expect(Row.amount_match(97, -100)).to eq(0.97)}
    specify { expect(Row.amount_match(150, -100)).to eq(0.5)}
    specify { expect(Row.amount_match(0, -100)).to eq(0.0)}
    specify { expect(Row.amount_match(200, -100)).to eq(0.0)}
    specify { expect(Row.amount_match(250, -100)).to eq(0.0)}
    specify { expect(Row.amount_match(350, -100)).to eq(0.0)}
    specify { expect(Row.amount_match(125, -100)).to eq(0.75)}
    specify { expect(Row.amount_match(175, -100)).to eq(0.25)}
    specify { expect(Row.amount_match(100, -100)).to eq(1.00)}
    specify { expect(Row.amount_match(100, 100)).to eq(0)}
    specify { expect(Row.amount_match(10, 2)).to eq(0)}
  end

  describe "#amount_cents" do
    it "converts string to cents integer" do
      row = new_row("17.9")
      expect(row.amount_cents).to eq 1790
    end
  end

  describe "#account_match" do
    it "matches row to customers account based on account balance and row amount" do
      row = new_row("20.01")
      customer = double("customer")
      customer.stub_chain(:account, :balance_cents).and_return(-2001)
      allow(row).to receive(:no_other_account_matches?).and_return(true)
      expect(row.account_match(customer)).to eq 1.0
    end
  end

  describe "#amount_valid?" do
    specify { expect(new_row("12.34").amount_valid?).to be true }
    specify { expect(new_row("1000").amount_valid?).to be true }
    specify { expect(new_row("-1.2").amount_valid?).to be true }
    specify { expect(new_row("+1.2").amount_valid?).to be true }
    specify { expect(new_row(".19").amount_valid?).to be true }
    specify { expect(new_row("-.19").amount_valid?).to be true }
  end
end

def new_row(amount_string)
  Row.new("2013-06-07","test row", amount_string)
end

def mock_customer(formated_number, balance = 0.0, orders = [0.0], first_name = nil, last_name = nil)
  # Setting the id below helps identify when a test fails
  mc = mock_model(Customer, formated_number: formated_number, id: formated_number)
  mc.stub_chain(:account, :balance, :to_f).and_return(balance)
  allow(mc).to receive(:orders).and_return(orders.collect{|o| double(Order, price: o)})
  allow(mc).to receive(:first_name).and_return(first_name) if first_name.present?
  allow(mc).to receive(:last_name).and_return(last_name) if last_name.present?
  mc
end

def real_customer(formated_number, balance = 0.0, orders = [0.0], first_name = nil, last_name = nil)
  c = Fabricate(:customer, number: formated_number.to_i)
  c.stub_chain(:account, :balance, :to_f).and_return(balance)
  allow(c).to receive(:orders).and_return(orders.collect{|o| double(Order, price: o)})
  c.first_name = first_name unless first_name.blank?
  c.last_name = last_name unless last_name.blank?
  c
end

def mock_customer_with_history(formated_number, opts = {})
  mc = mock_customer(formated_number)
  previous_matches = opts.delete(:previous_matches)
  allow(mc).to receive(:previous_matches).and_return(previous_matches)
  mc
end

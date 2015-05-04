require 'spec_helper'

include Bucky::TransactionImports

describe Bucky::TransactionImports::Row do
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

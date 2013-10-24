require 'spec_helper'

describe Account do
  let(:account) { Fabricate(:account) }
  let(:order) { Fabricate(:active_recurring_order) }
  let(:order_account) { order.account }

  specify { account.should be_valid }

  context :balance do
    specify { account.balance.cents.should eq 0 }
    specify { expect { account.balance_cents=(10) }.to raise_error(ArgumentError) }
    specify { expect { account.balance=(10) }.to raise_error(ArgumentError) }
  end

  context 'when updating balance' do
    describe '#create_transaction' do
      [-5, EasyMoney.new(0.01), 5].each do |value|
        context "with #{value} of type #{value.class}" do
          before do
            account.save
            account.create_transaction(value)
          end

          specify { account.balance.should eq value }
          specify { account.transactions.last.amount.should eq value }
        end
      end
    end

    describe '#add_to_balance' do
      [-5, 0.02, 5].each do |value|
        context "with #{value} of type #{value.class}" do
          before(:each) do
            account.save
            account.create_transaction(250)
            account.save
            account.add_to_balance(EasyMoney.new(value))
          end

          specify { account.balance.should eq (250 + value) }
          specify { account.transactions.last.amount.should eq value }
        end
      end
    end

    describe '#subtract_from_balance' do
      [-5, 0.03, 5].each do |value|
        context "with #{value} of type #{value.class}" do
          before(:each) do
            account.save
            account.create_transaction(250)
            account.save
            account.subtract_from_balance(EasyMoney.new(value))
          end

          specify { account.balance.should eq (250 - value) }
          specify { account.transactions.last.amount.should eq (-1 * value) }
        end
      end
    end

    describe '#change_balance_to!' do
      [-5, 0.04, 5].each do |value|
        context "with #{value} of type #{value.class}" do
          before(:each) do
            account.save
            account.create_transaction(250)
            account.save
            account.change_balance_to!(EasyMoney.new(value))
          end

          specify { account.balance.should eq value }
          specify { account.transactions.last.amount.should eq (value - 250)}
        end
      end
    end

    describe "#check_customer_threshold" do
      let(:customer) { account.customer }
      let(:distributor) { customer.distributor }

      it "updates halted status when balance changes" do
        
        account.should_receive(:update_halted_status)
        account.change_balance_to!(-100)
      end
    end
  end

  describe "#calculate_balance" do
    before do
      account.change_balance_to!(250)
      account.change_balance_to!(500)
    end

    it "should calculate balance correctly" do
      account.calculate_balance.should eq 500
    end
  end

  describe "#all_occurrences" do
    specify { order_account.all_occurrences(4.weeks.from_now).size.should eq 20 }
  end

  describe "#amount_with_bucky_fee" do
    it "returns amount if bucky fee is not separate" do
      account.distributor.stub(:separate_bucky_fee).and_return(true)
      account.distributor.stub(:bucky_box_percentage).and_return(0.02) #%
      account.amount_with_bucky_fee(100).should eq 102
    end

    it "includes bucky fee if bucky fee is separate" do
      account.distributor.stub(:separate_bucky_fee).and_return(false)
      account.distributor.stub(:bucky_box_percentage).and_return(0.02) #%
      account.amount_with_bucky_fee(100).should eq 100
    end
  end

  describe "create_invoice" do
    it "does nothing if an outstanding invoice exists" do
      account.save
      Fabricate(:invoice, account: account)
      account.stub(:next_invoice_date).and_return(Date.current)
      Invoice.should_not_receive(:create)
      account.create_invoice
    end

    it "does nothing if invoice_date is nil" do
      account.save
      Fabricate(:invoice, account: account)
      account.stub(:next_invoice_date).and_return(nil)
      Invoice.should_not_receive(:create)
      account.create_invoice
    end

    it "does nothing if next invoice date is after today" do
      account.stub(:next_invoice_date).and_return(1.day.from_now(Time.current))
      Invoice.should_not_receive(:create)
      account.create_invoice
    end

    it "creates invoice if next invoice date is <= today" do
      order_account.stub(:next_invoice_date).and_return(Date.current)
      Invoice.should_receive(:create_for_account)
      order_account.create_invoice
    end
  end

  describe "#need_invoicing" do
    before do
      @a1 = Fabricate.build(:account)
      @a1.stub(:needs_invoicing?).and_return(true)
      @a2 = Fabricate.build(:account)
      @a2.stub(:needs_invoicing?).and_return(false)

      Account.stub(:all).and_return [@a1, @a2]

      @accounts = Account.need_invoicing
    end

    specify { @accounts.should include(@a1) }
    specify { @accounts.should_not include(@a2) }
  end
end


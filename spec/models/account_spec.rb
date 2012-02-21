require 'spec_helper'

describe Account do
  before { @account = Fabricate(:account) }

  specify { @account.should be_valid }

  context :balance do
    specify { @account.balance_cents.should == 0 }
    specify { @account.currency.should == Money.default_currency.to_s }
    specify { expect { @account.balance_cents=(10) }.to raise_error(ArgumentError) }
    specify { expect { @account.balance=(10) }.to raise_error(ArgumentError) }
  end

  context 'when updating balance' do
    describe '#change_balance_to(amount)' do
      [-5, 0, 5].each do |v|
        context "with #{v} of type #{v.class}" do
          before { @account.change_balance_to(v) }
          specify { @account.balance.should == v.to_money }
          specify { @account.transactions.order(:created_at).last.amount.should == v.to_money }
        end
      end
    end

    describe '#add_to_balance' do
      [-5, 0, 5].each do |v|
        context "with #{v} of type #{v.class}" do
          before(:each) do
            @account.change_balance_to(250)
            @account.save
            @account.add_to_balance(v)
          end

          specify { @account.balance.should == (250 + v).to_money }
          specify { @account.transactions.unscoped.order(:id).last.amount.should == v.to_money }
        end
      end
    end

    describe '#subtract_from_balance' do
      [-5, 0, 5].each do |v|
        context "with #{v} of type #{v.class}" do
          before(:each) do
            @account.change_balance_to(250)
            @account.save
            @account.subtract_from_balance(v)
          end

          specify { @account.balance.should == (250 - v).to_money }
          specify { @account.transactions.unscoped.order(:id).last.amount.should == (-1 * v).to_money }
        end
      end
    end
  end

  describe "#calculate_balance" do
    before(:each) do
      @account.change_balance_to 250
      @account.change_balance_to 500
    end

    it "should calculate balance correctly" do
      @account.calculate_balance == 250
    end
  end

  describe "all_occurrences" do
    before(:each) do
      @order = order_with_deliveries
      @account = @order.account
    end
    it "returns 20 occurrences" do
      @account.all_occurrences(4.weeks.from_now).size.should == 20 
    end

  end

  describe "next_invoice_date" do
    context "20 deliveries loaded in the future" do
      before(:each) do
        @order = order_with_deliveries
        @account = @order.account
        @total_scheduled = @account.all_occurrences(4.weeks.from_now).inject(Money.new(0)) { |sum, o| sum += o[:price]}
      end

      it "is today if balance is currently below threshold" do
        @account.stub(:balance).and_return(Money.new(-1000))  
        @account.stub(:all_occurrences).and_return([])
        @account.next_invoice_date.should == Date.current
      end
      it "is at least 2 days after the first scheduled delivery" do
        @account.stub(:deliveries).and_return([])
        @account.stub(:balance).and_return(Money.new(1000))
        @account.next_invoice_date.should == 2.days.from_now(@account.all_occurrences(4.weeks.from_now).first[:date]).to_date
      end

      it "is 12 days before the account goes below the invoice threshold" do
        @account.stub(:balance).and_return(@total_scheduled - Money.new(1000))
        last_occurrence = @account.all_occurrences(4.weeks.from_now).last
        last_date = last_occurrence[:date]
        @account.next_invoice_date.should == 12.days.ago(last_date).to_date 
      end

      it "does not need an invoice if balance won't go below threshold" do
        @account.stub(:balance).and_return(@total_scheduled)
        @account.next_invoice_date.should be_nil
      end

      it "includes bucky fee in the calculations if distributor.separate_bucky_fee is true" do
        @account.stub(:balance).and_return(@total_scheduled - Money.new(499))
        @account.next_invoice_date.should_not be_nil
      end

      it "does not include bucky fee if distributor.separate_bucky_fee is false" do
        @order.distributor.update_attribute(:separate_bucky_fee, false)
        @account.stub(:balance).and_return(@total_scheduled - Money.new(499))
        @account.next_invoice_date.should be_nil
      end

      it "does include bucky fee in the calculations if distributor.separate_bucky_fee is true" do
        @account.distributor.update_attribute(:separate_bucky_fee, true)
        @account.stub(:balance).and_return(@total_scheduled - Money.new(499))
        @account.next_invoice_date.should_not be_nil
      end
    end
  end

  describe "#amount_with_bucky_fee" do
    it "returns amount if bucky fee is not separate" do
      @account.distributor.stub(:separate_bucky_fee).and_return(true)
      @account.distributor.stub(:bucky_box_percentage).and_return(0.02) #%
      @account.amount_with_bucky_fee(100).should == 102
    end
    it "includes bucky fee if bucky fee is separate" do
      @account.distributor.stub(:separate_bucky_fee).and_return(false)
      @account.distributor.stub(:bucky_box_percentage).and_return(0.02) #%
      @account.amount_with_bucky_fee(100).should == 100
    end
  end

  describe "create_invoice" do
    it "does nothing if an outstanding invoice exists" do
      Fabricate(:invoice, :account => @account)
      @account.stub(:next_invoice_date).and_return(Date.current)
      Invoice.should_not_receive(:create)
      @account.create_invoice
    end

    it "does nothing if invoice_date is nil" do
      Fabricate(:invoice, :account => @account)
      @account.stub(:next_invoice_date).and_return(nil)
      Invoice.should_not_receive(:create)
      @account.create_invoice
    end

    it "does nothing if next invoice date is after today" do
      @account.stub(:next_invoice_date).and_return(1.day.from_now(Time.now))
      Invoice.should_not_receive(:create)
      @account.create_invoice
    end

    it "creates invoice if next invoice date is <= today" do
      @account = order_with_deliveries.account
      @account.stub(:next_invoice_date).and_return(Date.current)
      Invoice.should_receive(:create_for_account)
      @account.create_invoice
    end
  end

  describe "#need_invoicing" do
    before(:each) do
      @a1 = Fabricate(:account)
      @a1.stub(:needs_invoicing?).and_return(true)
      @a2 = Fabricate(:account)
      @a2.stub(:needs_invoicing?).and_return(false)
      Account.stub(:all).and_return [@a1, @a2]
      @accounts = Account.need_invoicing
    end
    it "includes accounts that need invoicing" do
      @accounts.should include(@a1)
    end
    it "does not include accounts that need invoicing" do
      @accounts.should_not include(@a2)
    end
  end
end


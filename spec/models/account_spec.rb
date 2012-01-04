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
          specify { @account.transactions.last.amount.should == v.to_money }
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
          specify { @account.transactions.last.amount.should == v.to_money }
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
          specify { @account.transactions.last.amount.should == (-1 * v).to_money }
        end
      end
    end
  end

  describe "#recalculate_balance" do
    before(:each) do
      @account.change_balance_to 250
      @account.change_balance_to 500
      @transaction = @account.transactions.last
      @transaction.amount.should == 250
      @transaction.stub(:update_account_balance).and_return(true)
      @transaction.amount = 150
      @transaction.save
    end
    it "should recalculate balance correctly" do
      @account.balance.should == 500
      @account.recalculate_balance!
      @account.reload
      @account.balance.should == 400
    end
  end

  context 'when using tags' do
    before :each do
      @account.tag_list = 'dog, cat, rain'
      @account.save
    end

    specify { @account.tags.size.should == 3 }
    specify { @account.tag_list.should == %w(dog cat rain) }
  end

  describe "next_invoice_date" do
    before(:each) do
      pending('Invoices not done so not bothering to fix tests for them.')
      @order = Fabricate(:order) # $10
      @account = @order.account
      @d2 = Fabricate(:delivery, :delivery_list => Fabricate(:delivery_list, :date => 1.week.from_now), :order => @order)
      @d3 = Fabricate(:delivery, :delivery_list => Fabricate(:delivery_list, :date => 2.weeks.from_now), :order => @order)
      @d4 = Fabricate(:delivery, :delivery_list => Fabricate(:delivery_list, :date => 3.weeks.from_now), :order => @order)
      @d1 = Fabricate(:delivery, :delivery_list => Fabricate(:delivery_list, :date => Date.current), :order => @order)
    end

    it "is today if balance is currently below threshold" do
      @account.stub(:balance).and_return(Money.new(-1000))
      @account.next_invoice_date.should == 2.days.from_now(Time.now).to_date
    end

    it "is at least 2 days after the first delivery" do
      @account.stub(:balance).and_return(Money.new(0))  
      @account.next_invoice_date.should == 2.days.from_now(Time.now).to_date

      @account.stub(:balance).and_return(Money.new(1000))
      @account.next_invoice_date.should == 2.days.from_now(Time.now).to_date
    end

    it "is 12 days before the account goes below the invoice threshold" do
      @account.stub(:balance).and_return(Money.new(3000))
      @account.next_invoice_date.should == 12.days.ago(@d4.date).to_date 
    end

    it "is only influenced by pending deliveries" do
      @account.stub(:balance).and_return(Money.new(2000))
      @d3.update_attribute(:status, 'cancelled')
      @account.next_invoice_date.should == 12.days.ago(@d4.date).to_date  #skip cancelled order in calculation
    end

    it "does not need an invoice if balance won't go below threshold" do
      @account.stub(:balance).and_return(Money.new(5000))
      @account.next_invoice_date.should be_nil
    end

    it "includes bucky fee in the calculations if distributor.separate_bucky_fee is true" do
      @account.stub(:balance).and_return(Money.new(3501))
      @account.next_invoice_date.should_not be_nil
    end

    it "doesn't include bucky fee in the calculations if distributor.separate_bucky_fee is false" do
      @account.distributor.update_attribute(:separate_bucky_fee, false)
      @account.stub(:balance).and_return(Money.new(3501))
      @account.next_invoice_date.should be_nil
    end
  end

  describe "create_invoice" do
    before { pending('Invoices not done so not bothering to fix tests for them.') }

    it "does nothing if an outstanding invoice exists" do
      Fabricate(:invoice, :account => @account)
      @account.stub(:next_invoice_date).and_return(Date.current)
      Invoice.should_not_receive(:create)
      @account.create_invoice
    end

    it "does nothing if next invoice date is after today" do
      @account.stub(:next_invoice_date).and_return(1.day.from_now(Time.now))
      Invoice.should_not_receive(:create)
      @account.create_invoice
    end

    it "creates invoice if next invoice date is <= today" do
      @account.stub(:next_invoice_date).and_return(Date.current)
      Invoice.should_receive(:create).and_return(true)
      @account.create_invoice
    end
  end
end


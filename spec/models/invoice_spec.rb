require 'spec_helper'
describe Invoice do
  before(:each) do
    @invoice = Fabricate(:invoice)
    @account = @invoice.account
  end

  context "creating" do
    it "defaults start and end date" do
      @invoice.start_date.should == 4.weeks.ago.to_date
      @invoice.end_date.should == 4.weeks.from_now.to_date
    end
  end

  describe "#generate_invoices" do
    before(:each) do
      pending('Invoicing email generation is turned off for now')
      @account_due_today = Fabricaate(:active_recurring_order).account
      @account_due_today.stub(:next_invoice_date).and_return(Date.current)
      @account_due_tomorrow = Fabricaate(:active_recurring_order).account
      @account_due_tomorrow.stub(:next_invoice_date).and_return(1.day.from_now)
      @account_due_yesterday = Fabricaate(:active_recurring_order).account 
      @account_due_yesterday.stub(:next_invoice_date).and_return(1.day.ago)
      @account_with_invoice = Fabricaate(:active_recurring_order).account
      @account_with_invoice.stub(:next_invoice_date).and_return(Date.current)
      @account_with_invoice.create_invoice
      Account.stub(:all).and_return([@account_due_today,@account_due_tomorrow, @account_due_yesterday, @account_with_invoice])
      ActionMailer::Base.deliveries = []
      @invoices = Invoice.generate_invoices
      @invoiced_accounts = @invoices.collect {|i| i.account}
    end

    it "emails invoices to customers" do
      ActionMailer::Base.deliveries.size.should == @invoices.size
    end

    it "creates invoices for accounts that have an invoice date before today" do
      @invoiced_accounts.should include(@account_due_today, @account_due_yesterday)
    end

    it "does not create invoices for accounts due after today"  do
      @invoiced_accounts.should_not include(@account_due_tomorrow)
    end

    it "does not create invoices for accounts which have an outstanding invoice already"  do
      @invoiced_accounts.should_not include(@account_with_invoice)
    end
  end

  describe "calculate_amount" do
    context "with one scheduled delivery" do
      before(:each) do
        @order = Fabricate(:active_recurring_order)
        @account = @order.account
        @account.stub(:all_occurrences).and_return([{:price => @order.box.price}])
        @invoice = Fabricate(:invoice, :account => @account)
        @invoice.calculate_amount
      end

      it "should calculate correct amount" do
        pending 'Invoicing email generation is turned off for now'
        @invoice.amount.should == @account.amount_with_bucky_fee(@order.box.price)
      end
    end

    context "with multiple deliveries" do
      before(:each) do
        @order = Fabricate(:order)
        @account = @order.account
        @account.stub(:balance).and_return(Money.new(10000))
        @t1 = Fabricate(:transaction, :account => @account, :created_at => 3.days.ago)
        @t2 = Fabricate(:transaction, :account => @account, :created_at => Date.current)
        @invoice.account = @account
        @invoice.calculate_amount
      end

      it "copies the account balance" do
        @invoice.balance.should == @account.balance
      end

      it "should save transaction hash" do
        transaction_hash = @invoice.transactions.first
        transaction_hash[:date].should == @t1.created_at.to_date
        transaction_hash[:amount].should == @t1.amount
        transaction_hash[:description].should == @t1.description
      end

      it "should save deliveries hash" do
        @invoice.deliveries.size.should == @account.all_occurrences(4.weeks.from_now).size
      end

      xit "should include transactions on last day" do
        @invoice.transactions.size.should == 2
      end
    end
  end

  context "invoice numbers" do
    it "are generated on createion" do
      @invoice.number.should == 1
      i2 = Fabricate(:invoice, :account => @invoice.account)
      i2.number.should == 2
    end

    it "are unique for different customers" do
      @invoice.number.should == 1
      i2 = Fabricate(:invoice)
      i2.number.should == 1
    end
  end
end

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
  context "calculate_amount" do
    before(:each) do
      @order = Fabricate(:order)
      @account = @order.account
      @account.stub(:balance).and_return(Money.new(10000))
      @t1 = Fabricate(:transaction, :account => @account, :created_at => 3.days.ago)
      @t2 = Fabricate(:transaction, :account => @account, :created_at => Date.today)
      @d2 = Fabricate(:delivery, :order => @order, :date => 2.weeks.from_now)
      @d1 = Fabricate(:delivery, :order => @order, :date => 1.weeks.from_now)
      @d3 = Fabricate(:delivery, :order => @order, :date => 4.weeks.from_now)
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
      deliveries_hash = @invoice.deliveries.first
      deliveries_hash[:date].should == @d1.date.to_date
      deliveries_hash[:amount].should == @d1.order.price
      deliveries_hash[:description].should == @d1.box.name
    end
    it "should include deliveries on last day" do
      @invoice.deliveries.size.should == 3
    end
    it "should include transactions on last day" do
      @invoice.transactions.size.should == 2
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

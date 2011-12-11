require 'spec_helper'

describe Order do
  before { @order = Fabricate(:order) }

  specify { @order.should be_valid }

  context :quantity do
    specify { Fabricate.build(:order, :quantity => 0).should_not be_valid }
    specify { Fabricate.build(:order, :quantity => -1).should_not be_valid }
  end

  context :frequency do
    %w(single weekly fortnightly).each do |f|
      specify { Fabricate.build(:order, :frequency => f).should be_valid }
    end

    specify { Fabricate.build(:order, :frequency => 'yearly').should_not be_valid }
  end

  describe '#string_pluralize' do
    context "when the quantity is 1" do
      before { @order.quantity = 1 }
      specify { @order.string_pluralize.should == "1 #{@order.box.name}" }
    end

    [0, 2].each do |q|
      context "when the quantity is #{q}" do
        before { @order.quantity = q }
        specify { @order.string_pluralize.should == "#{q} #{@order.box.name}s" }
      end
    end
  end

  describe '#update_account' do
    context "when the order is new and has been marked as completed" do
      before do
        @original_account_balance = @order.account.balance
        @order.quantity = 5
        @order.completed = true
        @order.save
      end

      specify { @order.account.balance.should == @original_account_balance - (@order.box.price * @order.quantity) }
      specify { @order.account.transactions.last.kind.should == 'order' }
      specify { @order.account.transactions.last.amount.should == (@order.box.price * -1 * @order.quantity) }
    end

    context "when a previously completed order has its quantity changed" do
      before do
        @original_quantity = 10
        @order.completed = true

        @order.quantity = @original_quantity
        @order.save
      end

      [5, 15].each do |q|
        context "from 10 to #{q}" do
          before do
            @original_account_balance = @order.account.balance
            @change_in_quantity = q - @original_quantity

            @order.quantity = q
            @order.save
          end

          specify { @order.account.balance.should == @original_account_balance + (@order.box.price * -1 * @change_in_quantity) }
          specify { @order.account.transactions.last.kind.should == 'order' }
          specify { @order.account.transactions.last.amount.should == (@order.box.price * -1 * @change_in_quantity) }
        end
      end
    end
  end
end


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

  context 'when using tags' do
    before :each do
      @account.tag_list = 'dog, cat, rain'
      @account.save
    end

    specify { @account.tags.size.should == 3 }
    specify { @account.tag_list.should == %w(dog cat rain) }
  end
end


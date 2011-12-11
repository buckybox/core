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
          before(:each) do
            @account.change_balance_to(v)
            @account.save
          end

          specify { @account.balance.should == Money.new(v * 100) }
          specify { @account.transactions.last.amount.should == Money.new(v * 100) }
        end
      end
    end

    describe '#add_to_balance' do

    end

    describe '#subtract_from_balance' do

    end
  end
end


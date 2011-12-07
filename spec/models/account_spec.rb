require 'spec_helper'

describe Account do
  before :all do
    @account = Fabricate(:account)
  end

  specify { @account.should be_valid }

  context :balance do
    specify { @account.balance_cents.should == 0 }
    specify { @account.currency.should == 'NZD' }
    specify { lambda { @account.balance_cents=(10) }.should raise_error }
    specify { lambda { @account.balance=(10) }.should raise_error }
  end

  context 'when updating balance' do
    describe '#change_balance_to' do
      context "when valid" do
      end
    end

    describe '#add_to_balance' do

    end

    describe '#subtract_from_balance' do

    end
  end
end


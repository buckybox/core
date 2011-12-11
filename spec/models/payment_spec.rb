require 'spec_helper'

describe Payment do
  before :all do
    @payment = Fabricate(:payment)
  end

  specify { @payment.should be_valid }
  
  context :kinds do
    specify { Fabricate.build(:payment, :kind => 'cash').should_not be_valid }
  end

  context '#update_account' do
    specify { @payment.account.balance.should == @payment.amount }
    specify { @payment.account.transactions.should_not be_empty }
    specify { @payment.account.transactions.last.kind.should == 'payment' }
    specify { @payment.account.transactions.last.amount.should == @payment.amount }
  end
end


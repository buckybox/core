require 'spec_helper'

describe Payment do
  before do
    @payment = Fabricate(:payment)
  end

  specify { @payment.should be_valid }

  context :kinds do
    %w(bank_transfer credit_card unspecified).each do |k|
      specify { Fabricate.build(:payment, :kind => k).should be_valid }
    end

    specify { Fabricate.build(:payment, :kind => 'trees').should_not be_valid }
  end

  context '#update_account' do
    specify { @payment.account.balance.should == @payment.amount }
    specify { @payment.account.transactions.should_not be_empty }
    specify { @payment.account.transactions.last.kind.should == 'payment' }
    specify { @payment.account.transactions.last.amount.should == @payment.amount }
  end
end


require 'spec_helper'

describe Payment do
  let(:payment) { Fabricate.build(:payment) }

  specify { payment.should be_valid }

  context :kinds do
    %w(bank_transfer credit_card manual).each do |k|
      specify { Fabricate.build(:payment, kind: k).should be_valid }
    end

    specify { Fabricate.build(:payment, kind: 'trees').should_not be_valid }
  end

  context :amount do
    specify { Fabricate.build(:payment, amount: 0).should_not be_valid }
    specify { Fabricate.build(:payment, amount: -1).should_not be_valid }
  end

  context '#update_account' do
    before { payment.save }

    specify { payment.account.balance.should == payment.amount }
    specify { payment.transactions.should_not be_empty }
    specify { payment.transactions.last.transactionable.should == payment }
    specify { payment.transactions.last.amount.should == payment.amount }
  end
end


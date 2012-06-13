require 'spec_helper'

describe Payment do
  let(:payment) { Fabricate.build(:payment) }

  specify { payment.should be_valid }

  context :kinds do
    %w(bank_transfer credit_card delivery unspecified).each do |k|
      specify { Fabricate.build(:payment, kind: k).should be_valid }
    end

    specify { Fabricate.build(:payment, kind: 'trees').should_not be_valid }
  end

  context :source do
    %w(manual import pay_on_delivery).each do |s|
      specify { Fabricate.build(:payment, source: s).should be_valid }
    end

    specify { Fabricate.build(:payment, source: 'orange').should_not be_valid }
  end

  context :amount do
    specify { Fabricate.build(:payment, amount: 0).should be_valid }
    specify { Fabricate.build(:payment, amount: -1).should_not be_valid }
  end

  context 'affecting account balance' do
    before do
      @account_amount = payment.account.balance
      @amount = payment.amount
      payment.save
    end

    context 'after create' do
      specify { payment.transaction.should_not be_nil }
      specify { payment.transaction.persisted?.should be_true }
      specify { payment.transaction.amount.should == @amount }

      specify { payment.account.balance.should == @account_amount + @amount }
    end

    describe '#reverse_payment' do
      before { payment.reverse_payment! }

      specify { payment.reversed.should be_true }

      specify { payment.reversal_transaction.should_not be_nil }
      specify { payment.reversal_transaction.persisted?.should be_true }
      specify { payment.reversal_transaction.amount.should == -@amount }

      specify { payment.account.balance.should == @account_amount }
    end
  end
end


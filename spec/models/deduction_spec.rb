require 'spec_helper'

describe Deduction do
  let(:deduction) { Fabricate.build(:deduction) }

  specify { deduction.should be_valid }

  context :kinds do
    %w(delivery unspecified).each do |k|
      specify { Fabricate.build(:deduction, kind: k).should be_valid }
    end

    specify { Fabricate.build(:deduction, kind: 'trees').should_not be_valid }
  end

  context :source do
    %w(manual delivery).each do |s|
      specify { Fabricate.build(:deduction, source: s).should be_valid }
    end

    specify { Fabricate.build(:deduction, source: 'orange').should_not be_valid }
  end

  context :amount do
    specify { Fabricate.build(:deduction, amount: 0).should be_valid }
    specify { Fabricate.build(:deduction, amount: -1).should_not be_valid }
  end

  context 'affecting account balance' do
    before do
      @account_amount = deduction.account.balance
      @amount = deduction.amount
      deduction.save
    end

    context 'after create' do
      specify { deduction.transaction.should_not be_nil }
      specify { deduction.transaction.persisted?.should be_true }
      specify { deduction.transaction.amount.should == -@amount }

      specify { deduction.account.balance.should == @account_amount - @amount }
    end

    describe '#reverse_deduction' do
      before { deduction.reverse_deduction! }

      specify { deduction.reversed.should be_true }

      specify { deduction.reversal_transaction.should_not be_nil }
      specify { deduction.reversal_transaction.persisted?.should be_true }
      specify { deduction.reversal_transaction.amount.should == @amount }

      specify { deduction.account.balance.should == @account_amount }
    end
  end
end


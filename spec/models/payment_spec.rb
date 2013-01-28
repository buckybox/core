require 'spec_helper'

describe Payment do
  let(:payment) { Fabricate(:payment) }

  specify { payment.should be_valid }

  context :kinds do
    %w(bank_transfer credit_card delivery unspecified).each do |k|
      specify { Fabricate(:payment, kind: k).should be_valid }
    end

    specify { expect { Fabricate(:payment, kind: 'trees')}.to raise_error(ActiveRecord::RecordInvalid, /Kind trees is not a valid kind of payment/)}
  end

  context :source do
    %w(manual import).each do |s|
      specify { Fabricate(:payment, source: s).should be_valid }
    end

    specify { expect { Fabricate(:payment, source: 'orange')}.to raise_error(ActiveRecord::RecordInvalid, /Source orange is not a valid source of payment/)}
  end

  context :amount do
    specify { Fabricate(:payment, amount: 0).should be_valid }
    specify { Fabricate(:payment, amount: -1).should be_valid }
  end

  context 'affecting account balance' do
    before do
      @payment = Payment.new(amount: 1000)
      @customer = Fabricate(:customer)
      @distributor = @customer.distributor
      @account = @customer.account
      @payment.distributor = @distributor
      @payment.account = @account
      @payment.payable = Fabricate(:delivery)
      @payment.description = 'I love testing, could be a tui ad?'

      @account_amount = @payment.account.balance
      @amount = @payment.amount
      @payment.save!
    end

    context 'after create' do
      specify { @payment.transaction.should_not be_nil }
      specify { @payment.transaction.persisted?.should be_true }
      specify { @payment.transaction.amount.should == @amount }

      specify { @payment.account.balance.should == @account_amount + @amount }
    end

    describe '#reverse_payment' do
      before { @payment.reverse_payment! }

      specify { @payment.reversed.should be_true }

      specify { @payment.reversal_transaction.should_not be_nil }
      specify { @payment.reversal_transaction.persisted?.should be_true }
      specify { @payment.reversal_transaction.amount.should == -@amount }

      specify { @payment.account.balance.should == @account_amount }
    end
  end

  context 'negative payment reducing account' do
    let(:account){Fabricate(:account)}
    let(:payment){Fabricate(:payment, amount: -10, account: account)}
    
    it "should reduce account balance" do
      payment.save
      account.reload.balance_cents.should eq(-1000)
    end

  end
end


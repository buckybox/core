require 'spec_helper'

describe Payment, :slow do
  let(:payment) { Fabricate(:payment) }

  specify { expect(payment).to be_valid }

  context :kinds do
    %w(bank_transfer credit_card delivery unspecified).each do |k|
      specify { expect(Fabricate(:payment, kind: k)).to be_valid }
    end

    specify { expect { Fabricate(:payment, kind: 'trees')}.to raise_error(ActiveRecord::RecordInvalid, /Kind trees is not a valid kind of payment/)}
  end

  context :source do
    %w(manual import).each do |s|
      specify { expect(Fabricate(:payment, source: s)).to be_valid }
    end

    specify { expect { Fabricate(:payment, source: 'orange')}.to raise_error(ActiveRecord::RecordInvalid, /Source orange is not a valid source of payment/)}
  end

  context :amount do
    specify { expect(Fabricate(:payment, amount: 1)).to be_valid }
    specify { expect(Fabricate(:payment, amount: -1)).to be_valid }
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
      specify { expect(@payment.transaction).not_to be_nil }
      specify { expect(@payment.transaction.persisted?).to be true }
      specify { expect(@payment.transaction.amount).to eq @amount }

      specify { expect(@payment.account.balance).to eq @account_amount + @amount }
    end

    describe '#reverse_payment' do
      before { @payment.reverse_payment! }

      specify { expect(@payment.reversed).to be true }

      specify { expect(@payment.reversal_transaction).not_to be_nil }
      specify { expect(@payment.reversal_transaction.persisted?).to be true }
      specify { expect(@payment.reversal_transaction.amount).to eq @amount.opposite }

      specify { expect(@payment.account.balance).to eq @account_amount }
    end
  end

  context 'negative payment reducing account' do
    let(:account){Fabricate(:account)}
    let(:payment){Fabricate(:payment, amount: -10, account: account)}

    it "should reduce account balance" do
      payment.save
      expect(account.reload.balance_cents).to eq(-1000)
    end
  end
end


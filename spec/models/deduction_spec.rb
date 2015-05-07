require 'spec_helper'

describe Deduction, :slow do
  let(:deduction) { Fabricate(:deduction) }

  specify { expect(deduction).to be_valid }

  context :kinds do
    %w(delivery unspecified).each do |k|
      specify { expect(Fabricate(:deduction, kind: k)).to be_valid }
    end

    specify { expect(Fabricate.build(:deduction, kind: 'trees')).not_to be_valid }
  end

  context :source do
    %w(manual auto).each do |s|
      specify { expect(Fabricate(:deduction, source: s)).to be_valid }
    end

    specify { expect(Fabricate.build(:deduction, source: 'orange')).not_to be_valid }
  end

  context :amount do
    specify { expect(Fabricate(:deduction, amount: 1)).to be_valid }
    specify { expect(Fabricate.build(:deduction, amount: -1)).not_to be_valid }
  end

  context 'affecting account balance' do
    before do
      @deduction = Deduction.new
      @deduction.account = Fabricate(:account)
      @deduction.distributor = @deduction.account.customer.distributor
      @deduction.kind = 'delivery'
      @deduction.amount = 1000
      @deduction.description = 'descriptive task'
      @deduction.deductable = Fabricate(:delivery)
      @account_amount = @deduction.account.balance
      @amount = @deduction.amount
      @fee = CrazyMoney.new(0.25)
      @deduction.stub_chain(:distributor, :separate_bucky_fee).and_return(true)
      @deduction.stub_chain(:distributor, :consumer_delivery_fee).and_return(@fee)
      @deduction.save!
    end

    context 'after create' do
      specify { expect(@deduction.transaction).not_to be_nil }
      specify { expect(@deduction.transaction.persisted?).to be true }
      specify { expect(@deduction.transaction.amount).to eq @amount.opposite }

      specify { expect(@deduction.account.balance).to eq @account_amount - @amount - @fee}
      specify { expect(@deduction.bucky_fee.amount).to eq @fee.opposite }
    end

    describe '#reverse_deduction' do
      before { @deduction.reverse_deduction! }

      specify { expect(@deduction.reversed).to be true }

      specify { expect(@deduction.reversal_transaction).not_to be_nil }
      specify { expect(@deduction.reversal_transaction.persisted?).to be true }
      specify { expect(@deduction.reversal_transaction.amount).to eq @amount }
      specify { expect(@deduction.reversal_fee).not_to be_nil }

      specify { expect(@deduction.account.balance).to eq @account_amount }
    end
  end
end

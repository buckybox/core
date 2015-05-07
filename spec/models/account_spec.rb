require 'spec_helper'

describe Account do
  let(:account) { Fabricate(:account) }
  let(:order) { Fabricate(:active_recurring_order) }
  let(:order_account) { order.account }

  specify { expect(account).to be_valid }

  describe "#currency" do
    it "defaults to the customer's currency" do
      customer = Fabricate.build(:customer)
      allow(customer).to receive(:currency) { "EUR" }
      account = Fabricate(:account, customer: customer)

      expect(account.currency).to eq customer.currency
    end
  end

  context :balance do
    specify { expect(account.balance.cents).to eq 0 }
    specify { expect { account.balance_cents=(10) }.to raise_error(ArgumentError) }
    specify { expect { account.balance=(10) }.to raise_error(ArgumentError) }
  end

  context 'when updating balance' do
    describe '#create_transaction' do
      [-5, CrazyMoney.new(0.01), 5].each do |value|
        context "with #{value} of type #{value.class}" do
          before do
            account.save
            account.create_transaction(value)
          end

          specify { expect(account.balance).to eq value }
          specify { expect(account.transactions.last.amount).to eq value }
        end
      end
    end

    describe '#add_to_balance' do
      [-5, 0.02, 5].each do |value|
        context "with #{value} of type #{value.class}" do
          before(:each) do
            account.save
            account.create_transaction(250)
            account.save
            account.add_to_balance(CrazyMoney.new(value))
          end

          specify { expect(account.balance).to eq(250 + value) }
          specify { expect(account.transactions.last.amount).to eq value }
        end
      end
    end

    describe '#subtract_from_balance' do
      [-5, 0.03, 5].each do |value|
        context "with #{value} of type #{value.class}" do
          before(:each) do
            account.save
            account.create_transaction(250)
            account.save
            account.subtract_from_balance(CrazyMoney.new(value))
          end

          specify { expect(account.balance).to eq(250 - value) }
          specify { expect(account.transactions.last.amount).to eq(-1 * value) }
        end
      end
    end

    describe '#change_balance_to!' do
      [-5, 0.04, 5].each do |value|
        context "with #{value} of type #{value.class}" do
          before(:each) do
            account.save
            account.create_transaction(250)
            account.save
            account.change_balance_to!(CrazyMoney.new(value))
          end

          specify { expect(account.balance).to eq value }
          specify { expect(account.transactions.last.amount).to eq(value - 250)}
        end
      end
    end

    describe "#check_customer_threshold" do
      let(:customer) { account.customer }
      let(:distributor) { customer.distributor }

      it "updates halted status when balance changes" do
        expect(account).to receive(:update_halted_status)
        account.change_balance_to!(-100)
      end
    end
  end

  describe "#calculate_balance" do
    before do
      account.change_balance_to!(250)
      account.change_balance_to!(500)
    end

    it "should calculate balance correctly" do
      expect(account.calculate_balance).to eq 500
    end
  end

  describe "#all_occurrences" do
    specify { expect(order_account.all_occurrences(4.weeks.from_now.to_date).size).to eq 20 }
  end
end

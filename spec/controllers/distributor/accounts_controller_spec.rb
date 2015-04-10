require 'spec_helper'

describe Distributor::AccountsController do
  render_views

  sign_in_as_distributor
  let(:distributor) { @distributor }
  let(:customer) { Fabricate(:customer, distributor: distributor) }
  let(:account) { customer.account }

  describe "#change_balance" do
    it "updates customer balance" do
      balance_before = account.balance_cents
      expect do
        post :change_balance, id: customer.account.id, date: "22 Oct '13", delta: '6.66', note: 'hell pizza'
      end.to change{
        account.reload.balance_cents
      }.from(balance_before).to(balance_before + 666)
    end

    it "decreases customer balance" do
      balance_before = customer.account.balance_cents
      expect do
        post :change_balance, id: customer.account.id, date: "22 Oct '13", delta: '-6.66'
      end.to change{
        account.reload.balance_cents
      }.from(balance_before).to(balance_before - 666)
    end

    it "creates a transaction" do
      expect(account.transactions.count).to eq 0
      post :change_balance, id: customer.account.id, date: "20 Oct '13", delta: '-6.66', note: 'hell pizza'
      distributor.use_local_time_zone do
        transaction = account.reload.transactions.first
        expect(transaction).to be_present
        expect(transaction.display_time).to eq Date.parse("20 Oct '13").to_time_in_current_zone
        expect(transaction.amount_cents).to eq(-666)
        expect(transaction.description).to eq 'hell pizza'
      end
    end

    it "returns error for zero amount" do
      post :change_balance, id: customer.account.id, date: "22 Oct '13", delta: '', note: 'hell pizza'
      expect(flash[:error]).to eq "Change in balance must be a number and not zero."
    end

    it "halts account" do
      distributor.has_balance_threshold = true
      distributor.default_balance_threshold_cents = -100
      distributor.save!
      customer.balance_threshold_cents = -100
      customer.save!

      post :change_balance, id: customer.account.id, date: "22 Oct '13", delta: (CrazyMoney.new(-5) - account.balance), note: 'hell pizza'
      expect(customer.reload).to be_halted
    end
  end
end

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
      expect{
        post :change_balance, id: customer.account.id, date: "22 Oct '13", delta: '6.66', note: 'hell pizza'
      }.to change{
        account.reload.balance_cents
      }.from(balance_before).to(balance_before + 666)
    end

    it "decreases customer balance" do
      balance_before = customer.account.balance_cents
      expect{
        post :change_balance, id: customer.account.id, date: "22 Oct '13", delta: '-6.66'
      }.to change{
        account.reload.balance_cents
      }.from(balance_before).to(balance_before - 666)
    end

    it "creates a transaction" do
      account.transactions.count.should eq 0
      post :change_balance, id: customer.account.id, date: "20 Oct '13", delta: '-6.66', note: 'hell pizza'
      distributor.use_local_time_zone do
        transaction = account.reload.transactions.first
        transaction.should be_present
        transaction.display_time.should eq Date.parse("20 Oct '13").to_time_in_current_zone
        transaction.amount_cents.should eq(-666)
        transaction.description.should eq 'hell pizza'
      end
    end

    it "returns error for zero amount" do
      post :change_balance, id: customer.account.id, date: "22 Oct '13", delta: '', note: 'hell pizza'
      flash[:error].should eq "Change in balance must be a number and not zero."
    end

    it "halts account" do
      distributor.has_balance_threshold = true
      distributor.default_balance_threshold_cents = -100
      distributor.save!
      customer.balance_threshold_cents = -100
      customer.save!

      post :change_balance, id: customer.account.id, date: "22 Oct '13", delta: (EasyMoney.new(-5) - account.balance), note: 'hell pizza'
      customer.reload.should be_halted
    end
  end
end

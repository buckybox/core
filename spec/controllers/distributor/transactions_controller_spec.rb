require 'spec_helper'

describe Distributor::TransactionsController do
  before(:each) do
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    sign_in @distributor
    @account = Fabricate(:account, :distributor => @distributor)
    @transaction = Fabricate(:transaction, :account => @account)
  end

  context "on destroy" do
    it "updates account balance" do
      lambda {
        post :destroy, :distributor_id => @transaction.account.distributor.id, :id => @transaction.id
        @account.recalculate_balance!
      }.should change {@account.reload.balance}.by(@transaction.amount * -1)
    end
    it "destroys transaction" do
      lambda {
        post :destroy, :distributor_id => @transaction.account.distributor.id, :id => @transaction.id
      }.should change {Transaction.count}.by(-1)
    end
  end

end

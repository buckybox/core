require 'spec_helper'

describe Distributor::TransactionsController do
  before(:each) do
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    sign_in @distributor
    @account = Fabricate(:account, :distributor => @distributor)
    @transaction = Fabricate(:transaction, :account => @account)
  end
end

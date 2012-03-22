require 'spec_helper'

describe Distributor::TransactionsController do
  as_distributor

  before(:each) do
    @account = Fabricate(:account, :distributor => @distributor)
    @transaction = Fabricate(:transaction, :account => @account)
  end
end

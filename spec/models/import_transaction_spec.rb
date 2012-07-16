require 'spec_helper'

describe ImportTransaction do
  context :process_negative_transactions do

    it "should process negative import transactions" do
      import_transaction = Fabricate(:import_transaction, amount_cents: -1423, customer_id: nil, match: ImportTransaction::MATCH_NOT_A_CUSTOMER )
      
      account = mock_model(Account)
      
      customer = mock_model(Customer, account: account)
      import_transaction.stub(:account).and_return(account)

      import_transaction.should_receive(:create_payment)

      import_transaction.match = ImportTransaction::MATCH_MATCHED
      import_transaction.stub(:customer).and_return(customer)
      import_transaction.save
    end
  end
end

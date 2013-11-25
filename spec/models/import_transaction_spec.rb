require 'spec_helper'

describe ImportTransaction do
  context :process_negative_transactions do

    let(:import_transaction){ import_transaction = Fabricate(:import_transaction, amount_cents: -1423, customer_id: nil, match: ImportTransaction::MATCH_NOT_A_CUSTOMER )}
    let(:account) do
      a = mock_model(Account)
      a.stub(:changed_for_autosave?).and_return(false)
      a.stub(:add_to_balance)
      a
    end
    let(:customer){mock_model(Customer, account: account)}

    before do
      import_transaction.stub(:account).and_return(account)
      import_transaction.stub(:distributor_customer_ids).and_return([customer.id])
    end

    it "should process negative import transactions" do
      import_transaction.should_receive(:create_payment)

      import_transaction.match = ImportTransaction::MATCH_MATCHED
      import_transaction.stub(:customer).and_return(customer)
      import_transaction.stub(:customer_id).and_return(customer.id)
      import_transaction.save
    end

    it "should create 'payment' labeled payments when positive amount" do
      import_transaction.amount_cents = 1423
      import_transaction.match = ImportTransaction::MATCH_MATCHED
      import_transaction.stub(:customer).and_return(customer)
      import_transaction.stub(:customer_id).and_return(customer.id)
      import_transaction.save

      import_transaction.payment.description.should match("Payment")
    end

    it "should create 'payment' labeled payments when positive amount" do
      import_transaction.match = ImportTransaction::MATCH_MATCHED
      import_transaction.stub(:customer).and_return(customer)
      import_transaction.stub(:customer_id).and_return(customer.id)
      import_transaction.save

      import_transaction.payment.description.should match("Refund")
    end
  end
end

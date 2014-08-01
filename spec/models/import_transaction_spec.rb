require 'spec_helper'

describe ImportTransaction do
  context :process_negative_transactions do

    let(:import_transaction){ import_transaction = Fabricate(:import_transaction, amount_cents: -1423, customer_id: nil, match: ImportTransaction::MATCH_NOT_A_CUSTOMER )}
    let(:account) do
      a = mock_model(Account)
      allow(a).to receive(:changed_for_autosave?).and_return(false)
      allow(a).to receive(:add_to_balance)
      a
    end
    let(:customer){mock_model(Customer, account: account)}

    before do
      allow(import_transaction).to receive(:account).and_return(account)
      allow(import_transaction).to receive(:distributor_customer_ids).and_return([customer.id])
    end

    it "should process negative import transactions" do
      expect(import_transaction).to receive(:create_payment)

      import_transaction.match = ImportTransaction::MATCH_MATCHED
      allow(import_transaction).to receive(:customer).and_return(customer)
      allow(import_transaction).to receive(:customer_id).and_return(customer.id)
      import_transaction.save
    end

    it "should create 'payment' labeled payments when positive amount" do
      import_transaction.amount_cents = 1423
      import_transaction.match = ImportTransaction::MATCH_MATCHED
      allow(import_transaction).to receive(:customer).and_return(customer)
      allow(import_transaction).to receive(:customer_id).and_return(customer.id)
      import_transaction.save

      expect(import_transaction.payment.description).to match("Payment")
    end

    it "should create 'payment' labeled payments when positive amount" do
      import_transaction.match = ImportTransaction::MATCH_MATCHED
      allow(import_transaction).to receive(:customer).and_return(customer)
      allow(import_transaction).to receive(:customer_id).and_return(customer.id)
      import_transaction.save

      expect(import_transaction.payment.description).to match("Refund")
    end
  end
end

class CreateDeductionsForPastDeliveries < ActiveRecord::Migration
  class Transaction < ActiveRecord::Base; end
  class Deduction < ActiveRecord::Base; end
  class Account < ActiveRecord::Base; end
  class Customer < ActiveRecord::Base; end

  def up
    Transaction.reset_column_information
    Deduction.reset_column_information
    Account.reset_column_information
    Customer.reset_column_information

    Transaction.where(transactionable_type: 'Delivery').each do |transaction|
      deductable_id  = transaction.read_attribute(:transactionable_id)
      account_id     = transaction.read_attribute(:account_id)
      amount_cents   = transaction.read_attribute(:amount_cents) * -1
      currency       = transaction.read_attribute(:currency)
      description    = transaction.read_attribute(:description)
      created_at     = transaction.read_attribute(:created_at)

      account        = Account.find_by_id(account_id)

      if account
        customer_id    = account.read_attribute(:customer_id)
        customer       = Customer.find_by_id(customer_id)
        distributor_id = customer.read_attribute(:distributor_id)

        deduction = Deduction.create(
          distributor_id: distributor_id,
          account_id: account_id,
          amount_cents: amount_cents,
          currency: currency,
          description: description,
          deductable_id: deductable_id,
          deductable_type: 'Delivery',
          reversed: false,
          kind: 'delivery',
          source: 'auto',
          display_time: created_at,
          transaction_id: transaction.id
        )

        deductable_id = deduction.read_attribute(:id)

        transaction.update_attribute(:transactionable_type, 'Deduction')
        transaction.update_attribute(:transactionable_id, deductable_id)
      end
    end
  end

  def down
    # Hard to go back from this one after new data has been added to the system
  end
end

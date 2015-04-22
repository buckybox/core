class RemoveCreditCardTransactions < ActiveRecord::Migration
  def change
    drop_table :credit_card_transactions
  end
end

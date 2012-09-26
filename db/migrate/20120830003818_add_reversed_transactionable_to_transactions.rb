class AddReversedTransactionableToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :reverse_transactionable_id, :integer
    add_column :transactions, :reverse_transactionable_type, :string
  end
end

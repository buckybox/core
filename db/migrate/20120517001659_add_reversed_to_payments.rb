class AddReversedToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :reversed, :boolean
    add_column :payments, :reversed_at, :timestamp
    add_column :payments, :transaction_id, :integer
    add_column :payments, :reversal_transaction_id, :integer
    add_column :payments, :source, :string
  end
end

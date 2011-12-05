class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.references :distributor
      t.references :customer
      t.references :transactionable, :polymorphic => true
      t.integer :amount_cents, :default => 0, :null => false
      t.string :currency
      t.text :description

      t.timestamps
    end
    add_index :transactions, :distributor_id
    add_index :transactions, :customer_id
    add_index :transactions, :transactionable_id
  end
end

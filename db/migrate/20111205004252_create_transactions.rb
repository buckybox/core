class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.references :account
      t.string :kind
      t.integer :amount_cents, :default => 0, :null => false
      t.string :currency
      t.text :description

      t.timestamps
    end
    add_index :transactions, :account_id
  end
end

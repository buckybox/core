class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.references :distributor
      t.references :customer
      t.references :account
      t.integer :amount_cents, :default => 0, :null => false
      t.string :currency
      t.string :kind
      t.text :description

      t.timestamps
    end
    add_index :payments, :distributor_id
    add_index :payments, :customer_id
    add_index :payments, :account_id
  end
end

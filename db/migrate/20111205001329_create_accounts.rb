class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.references :distributor
      t.references :customer
      t.integer :balance_cents, :default => 0, :null => false
      t.string :currenty

      t.timestamps
    end
    add_index :accounts, :distributor_id
    add_index :accounts, :customer_id
  end
end

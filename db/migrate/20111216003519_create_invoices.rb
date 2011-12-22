class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.references :account
      t.integer :number
      t.integer :amount_cents
      t.integer :balance_cents
      t.string :currency
      t.date :date
      t.date :start_date
      t.date :end_date
      t.text :transactions
      t.text :deliveries
      t.boolean :paid, :default => false
      t.timestamps
    end
  end
end

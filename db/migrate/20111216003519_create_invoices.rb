class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.references :order
      t.integer :number
      t.date :date
      t.date :start_date
      t.date :end_date
      t.text :transactions
      t.text :deliveries
      t.timestamps
    end
  end
end

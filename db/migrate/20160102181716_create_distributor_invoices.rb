class CreateDistributorInvoices < ActiveRecord::Migration
  def change
    create_table :distributor_invoices do |t|
      t.belongs_to :distributor, index: true, null: false

      t.date :from, null: false
      t.date :to, null: false
      t.text :description, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false

      t.timestamps
    end
  end
end

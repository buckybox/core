class AddNumberToInvoices < ActiveRecord::Migration
  def change
    add_column :distributor_invoices, :number, :string, null: true
  end
end

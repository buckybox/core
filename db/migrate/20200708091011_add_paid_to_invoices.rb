class AddPaidToInvoices < ActiveRecord::Migration
  def change
    add_column :distributor_invoices, :paid, :bool, null: false, default: false
  end
end

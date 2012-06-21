class AddPaymentIdToImportTransaction < ActiveRecord::Migration
  def change
    add_column :import_transactions, :payment_id, :integer
  end
end

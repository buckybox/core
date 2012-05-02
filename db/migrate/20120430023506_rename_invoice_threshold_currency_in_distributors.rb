class RenameInvoiceThresholdCurrencyInDistributors < ActiveRecord::Migration
  def change
    rename_column :distributors, :currency, :invoice_threshold_currency
  end
end

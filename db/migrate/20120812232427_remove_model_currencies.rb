class RemoveModelCurrencies < ActiveRecord::Migration
  def up
    remove_column :accounts, :currency
    remove_column :boxes, :currency
    remove_column :deductions, :currency
    remove_column :distributors, :invoice_threshold_currency
    remove_column :extras, :currency
    remove_column :invoices, :currency
    remove_column :packages, :archived_fee_currency
    rename_column :packages, :archived_price_currency, :currency
    remove_column :payments, :currency
    remove_column :routes, :currency
  end

  def down
    add_column :routes, :currency, :string
    add_column :payments, :currency, :string
    rename_column :packages, :currency, :archived_price_currency
    add_column :packages, :archived_fee_currency, :string
    add_column :invoices, :currency, :string
    add_column :extras, :currency, :string
    add_column :distributors, :invoice_threshold_currency, :string
    add_column :deductions, :currency, :string
    add_column :boxes, :currency, :string
    add_column :accounts, :currency, :string
  end
end

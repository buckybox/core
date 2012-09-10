class RenameModelCurrencies < ActiveRecord::Migration
  def up
    rename_column :packages, :archived_price_currency, :currency
    remove_column :packages, :archived_fee_currency
    remove_column :distributors, :invoice_threshold_currency
  end

  def down
    add_column :distributors, :invoice_threshold_currency, :string
    add_column :packages, :archived_fee_currency, :string
    rename_column :packages, :currency, :archived_price_currency
  end
end


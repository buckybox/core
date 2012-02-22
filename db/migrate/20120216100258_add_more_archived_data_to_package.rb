class AddMoreArchivedDataToPackage < ActiveRecord::Migration
  def change
    rename_column :packages, :archived_currency, :archived_price_currency
    add_column :packages, :archived_fee_cents, :integer, default: 0
    add_column :packages, :archived_fee_currency, :string
    add_column :packages, :archived_customer_discount, :decimal, default: 0, null: false
  end
end

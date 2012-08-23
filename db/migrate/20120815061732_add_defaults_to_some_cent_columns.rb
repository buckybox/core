class AddDefaultsToSomeCentColumns < ActiveRecord::Migration
  def up
    change_column :deductions, :amount_cents, :integer, default: 0, null: false
    change_column :distributors, :invoice_threshold_cents, :integer, default: 0, null: false
    change_column :extras, :price_cents, :integer, default: 0, null: false
    change_column :import_transactions, :amount_cents, :integer, default: 0, null: false
    change_column :invoices, :amount_cents, :integer, default: 0, null: false
    change_column :invoices, :balance_cents, :integer, default: 0, null: false
    change_column :packages, :archived_price_cents, :integer, default: 0, null: false
    change_column :packages, :archived_fee_cents, :integer, default: 0, null: false
    change_column :routes, :fee_cents, :integer, default: 0, null: false
  end

  def down
    change_column :routes, :fee_cents, :integer, default: 0, null: true
    change_column :packages, :archived_fee_cents, :integer, default: 0, null: true
    change_column :packages, :archived_price_cents, :integer, default: 0, null: true
    change_column :invoices, :balance_cents, :integer, null: true
    change_column :invoices, :amount_cents, :integer, null: true
    change_column :import_transactions, :amount_cents, :integer, null: true
    change_column :extras, :price_cents, :integer, null: true
    change_column :distributors, :invoice_threshold_cents, :integer, default: -500, null: true
    change_column :deductions, :amount_cents, :integer, null: true
  end
end


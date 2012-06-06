class AddPaymentsSettingsToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :bank_deposit, :boolean
    add_column :distributors, :paypal, :boolean
    add_column :distributors, :bank_deposit_format, :string
  end
end

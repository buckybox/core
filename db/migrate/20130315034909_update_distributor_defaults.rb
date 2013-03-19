class UpdateDistributorDefaults < ActiveRecord::Migration
  def change
    remove_column :distributors, :bank_deposit
    remove_column :distributors, :paypal
    remove_column :distributors, :bank_deposit_format

    remove_column :import_transaction_lists, :file_format

    change_column :distributors, :feature_spend_limit, :boolean, default: true
  end
end

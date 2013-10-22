class AddStatusToImportTransactionList < ActiveRecord::Migration
  def change
    add_column :import_transaction_lists, :status, :string
  end
end

class AddIndexesToImportTransactions < ActiveRecord::Migration
  def change
    add_index(:import_transactions, :import_transaction_list_id)
    add_index(:import_transactions, [:import_transaction_list_id, :removed], name: "index_import_removed")
    add_index(:import_transactions, [:import_transaction_list_id, :draft], name: "index_import_draft")
    add_index(:import_transactions, [:import_transaction_list_id, :match], name: "index_import_match")

    add_index(:import_transaction_lists, [:distributor_id, :draft])
  end
end

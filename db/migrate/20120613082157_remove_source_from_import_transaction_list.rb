class RemoveSourceFromImportTransactionList < ActiveRecord::Migration
  def up
    remove_column :import_transaction_lists, :source_type
  end

  def down
    add_column :import_transaction_lists, :source_type, :string
  end
end

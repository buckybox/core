class AddFileFormatToImportTransactionList < ActiveRecord::Migration
  def change
    add_column :import_transaction_lists, :file_format, :string
  end
end

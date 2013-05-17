class UpdateCsvFileToTextOnImportTransactionLists < ActiveRecord::Migration
  def up
    change_column :import_transaction_lists, :csv_file, :text
  end

  def down
    change_column :import_transaction_lists, :csv_file, :string
  end
end

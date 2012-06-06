class AddRawDataToImportTransaction < ActiveRecord::Migration
  def change
    add_column :import_transactions, :raw_data, :text
  end
end

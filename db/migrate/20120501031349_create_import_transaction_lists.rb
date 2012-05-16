class CreateImportTransactionLists < ActiveRecord::Migration
  def change
    create_table :import_transaction_lists do |t|
      t.integer :distributor_id
      t.boolean :draft
      t.integer :account_type
      t.integer :source_type
      t.string :csv_file
      t.boolean :confirmed

      t.timestamps
    end
  end
end

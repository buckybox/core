class CreateImportTransactions < ActiveRecord::Migration
  def change
    create_table :import_transactions do |t|
      t.integer :customer_id
      t.timestamp :transaction_time
      t.integer :amount_cents
      t.boolean :removed
      t.text :description
      t.float :confidence
      t.integer :import_transaction_list_id
      t.integer :match

      t.timestamps
    end
  end
end

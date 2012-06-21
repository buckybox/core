class CreateImportTransactions < ActiveRecord::Migration
  def change
    create_table :import_transactions do |t|
      t.integer :customer_id
      t.date :transaction_date
      t.integer :amount_cents
      t.boolean :removed
      t.text :description
      t.float :confidence
      t.integer :import_transaction_list_id
      t.integer :match
      t.integer :transaction_id
      t.boolean :draft

      t.timestamps
    end
  end
end

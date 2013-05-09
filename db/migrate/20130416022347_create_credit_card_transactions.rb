class CreateCreditCardTransactions < ActiveRecord::Migration
  def change
    create_table :credit_card_transactions do |t|
      t.integer :amount
      t.boolean :success
      t.string :reference
      t.string :message
      t.string :action
      t.text :params
      t.boolean :test
      t.integer :distributor_id
      t.integer :account_id

      t.timestamps
    end
  end
end

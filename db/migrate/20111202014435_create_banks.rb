class CreateBanks < ActiveRecord::Migration
  def change
    create_table :banks do |t|
      t.references :distributor
      t.string :name
      t.string :account_name
      t.string :account_number
      t.text :customer_message

      t.timestamps
    end
    add_index :banks, :distributor_id
  end
end

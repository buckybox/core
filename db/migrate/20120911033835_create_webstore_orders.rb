class CreateWebstoreOrders < ActiveRecord::Migration
  def change
    create_table :webstore_orders do |t|
      t.references :account
      t.references :box
      t.text :exclusions
      t.text :substitutions
      t.text :extras
      t.string :status
      t.string :remote_ip

      t.timestamps
    end
  end
end

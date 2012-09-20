class CreateWebstoreOrders < ActiveRecord::Migration
  def change
    create_table :webstore_orders do |t|
      t.references :account
      t.references :box
      t.references :route
      t.text :exclusions
      t.text :substitutions
      t.text :extras
      t.string :remote_ip

      t.timestamps
    end
  end
end

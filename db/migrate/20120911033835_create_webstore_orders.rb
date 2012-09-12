class CreateWebstoreOrders < ActiveRecord::Migration
  def change
    create_table :webstore_orders do |t|
      t.references :distributor
      t.references :box
      t.references :order
      t.references :route
      t.references :account
      t.string :status

      t.timestamps
    end
  end
end

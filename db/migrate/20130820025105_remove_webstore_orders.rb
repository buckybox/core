class RemoveWebstoreOrders < ActiveRecord::Migration
  def change
    drop_table :webstore_orders
  end
end

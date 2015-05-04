class RemoveWebstoreCartPersistences < ActiveRecord::Migration
  def change
    drop_table :webstore_cart_persistences
  end
end

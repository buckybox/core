class CreateWebstoreCartPersistance < ActiveRecord::Migration
  def change
    create_table :webstore_cart_persistances do |t|
      t.text :collected_data

      t.timestamps
    end
  end
end

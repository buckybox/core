class AddUniquenessConstraintToPackagesAndDeliveries < ActiveRecord::Migration
  def change
    remove_index :packages, :order_id

    add_index :packages, [:packing_list_id, :order_id], unique: true
    add_index :deliveries, [:delivery_list_id, :order_id], unique: true
  end
end

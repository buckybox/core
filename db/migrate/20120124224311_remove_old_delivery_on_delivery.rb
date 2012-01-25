class RemoveOldDeliveryOnDelivery < ActiveRecord::Migration
  def up
    remove_column :deliveries, :old_delivery_id
  end

  def down
    add_column :deliveries, :old_delivery_id, :integer
  end
end

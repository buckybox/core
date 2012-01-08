class AddOldDeliveryToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :old_delivery_id, :integer
  end
end

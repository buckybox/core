class AddPickupPointBooleanToDeliveryServices < ActiveRecord::Migration
  def change
    add_column :delivery_services, :pickup_point, :boolean, default: false, null: false
  end
end

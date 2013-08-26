class RenameRouteToDeliveryService2 < ActiveRecord::Migration
  def up
    execute("UPDATE schedule_rules SET scheduleable_type = 'DeliveryService' WHERE scheduleable_type = 'Route'")
    execute("UPDATE webstore_cart_persistences SET collected_data = REPLACE(collected_data, 'Route', 'DeliveryService')")
  end

  def down
    execute("UPDATE schedule_rules SET scheduleable_type = 'Route' WHERE scheduleable_type = 'DeliveryService'")
    execute("UPDATE webstore_cart_persistences SET collected_data = REPLACE(collected_data, 'DeliveryService', 'Route')")
  end
end

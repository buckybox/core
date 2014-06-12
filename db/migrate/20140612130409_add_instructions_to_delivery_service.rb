class AddInstructionsToDeliveryService < ActiveRecord::Migration
  class DeliveryService < ActiveRecord::Base; end

  def up
    add_column :delivery_services, :instructions, :text

    DeliveryService.update_all("instructions = (area_of_service || '\r\n\r\n' || estimated_delivery_time)")

    remove_column :delivery_services, :area_of_service
    remove_column :delivery_services, :estimated_delivery_time
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

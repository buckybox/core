class UpdateNullDeliveryMethods < ActiveRecord::Migration
  class Delivery < ActiveRecord::Base; end

  def up
    Delivery.reset_column_information

    Delivery.all.each do |delivery|
      value = delivery.read_attribute(:delivery_method)

      if value.nil?
        delivery.update_attribute(:delivery_method, 'auto')
      end
    end

    rename_column :deliveries, :delivery_method, :status_change_type
  end

  def down
    rename_column :deliveries, :status_change_type, :delivery_method

    # Can not rollback this data migration
  end
end

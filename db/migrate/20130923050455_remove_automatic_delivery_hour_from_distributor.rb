class RemoveAutomaticDeliveryHourFromDistributor < ActiveRecord::Migration
  def change
    remove_column :distributors, :automatic_delivery_hour
  end
end

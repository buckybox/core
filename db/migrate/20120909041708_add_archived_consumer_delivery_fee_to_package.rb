class AddArchivedConsumerDeliveryFeeToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :archived_consumer_delivery_fee_cents, :integer, default: 0
  end
end

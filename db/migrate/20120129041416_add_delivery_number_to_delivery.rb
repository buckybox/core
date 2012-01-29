class AddDeliveryNumberToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :delivery_number, :integer
  end
end

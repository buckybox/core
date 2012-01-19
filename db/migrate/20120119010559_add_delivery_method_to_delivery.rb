class AddDeliveryMethodToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :delivery_method, :string
  end
end

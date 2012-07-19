class CreateDeliverySequenceOrders < ActiveRecord::Migration
  def change
    create_table :delivery_sequence_orders do |t|
      t.integer :address_id
      t.integer :route_id
      t.integer :day
      t.integer :position

      t.timestamps
    end
  end
end

class CreateDeliverySequenceOrders < ActiveRecord::Migration
  def change
    create_table :delivery_sequence_orders do |t|
      t.string :address_hash
      t.integer :route_id
      t.integer :day
      t.integer :position

      t.timestamps
    end

    add_column :deliveries, :dso, :integer, default: -1
  end
end

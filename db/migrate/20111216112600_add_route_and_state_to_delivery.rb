class AddRouteAndStateToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :status, :string
    add_column :deliveries, :route_id, :integer
    add_index :deliveries, :route_id
  end
end

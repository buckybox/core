class AddRouteToWebstoreOrder < ActiveRecord::Migration
  def change
    add_column :webstore_orders, :route_id, :integer
  end
end

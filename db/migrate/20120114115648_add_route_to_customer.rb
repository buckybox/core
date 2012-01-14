class AddRouteToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :route_id, :integer
    add_index :customers, :route_id
  end
end

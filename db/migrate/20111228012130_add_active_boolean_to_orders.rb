class AddActiveBooleanToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :active, :boolean, :default => true, :null => false
  end
end

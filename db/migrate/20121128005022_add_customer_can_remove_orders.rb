class AddCustomerCanRemoveOrders < ActiveRecord::Migration
  def up
    add_column :distributors, :customer_can_remove_orders, :boolean, default: false

    Distributor.reset_column_information

    Distributor.update_all("customer_can_remove_orders = 'f'")
  end

  def down
    remove_column :distributors, :customer_can_remove_orders
  end
end

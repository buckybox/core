class AddCustomerCanEditOrdersToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :customer_can_edit_orders, :boolean, null: false, default: true
  end
end

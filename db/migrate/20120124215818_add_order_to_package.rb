class AddOrderToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :order_id, :integer
    add_index :packages, :order_id
  end
end

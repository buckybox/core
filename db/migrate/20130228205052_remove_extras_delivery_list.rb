class RemoveExtrasDeliveryList < ActiveRecord::Migration
  def change
    add_column :orders, :extras_packing_list_id, :integer
    remove_column :orders, :extras_delivery_list_id
  end
end

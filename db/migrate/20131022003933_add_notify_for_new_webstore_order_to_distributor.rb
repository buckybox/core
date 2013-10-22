class AddNotifyForNewWebstoreOrderToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :notify_for_new_webstore_order, :boolean, null: false, default: false
  end
end

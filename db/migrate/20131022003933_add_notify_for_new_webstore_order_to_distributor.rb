class AddNotifyForNewWebstoreOrderToDistributor < ActiveRecord::Migration
  class Distributor < ActiveRecord::Base; end

  def up
    # default to true for new distributors
    add_column :distributors, :notify_for_new_webstore_order, :boolean, null: false, default: true

    Distributor.reset_column_information
    # leave it disabled for existing distributors
    Distributor.update_all(notify_for_new_webstore_order: false)
  end

  def down
    remove_column :distributors, :notify_for_new_webstore_order
  end
end

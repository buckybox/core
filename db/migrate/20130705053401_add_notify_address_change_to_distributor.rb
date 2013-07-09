class AddNotifyAddressChangeToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :notify_address_change, :boolean
  end
end

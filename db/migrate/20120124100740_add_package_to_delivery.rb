class AddPackageToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :package_id, :integer
    add_index :deliveries, :package_id
  end
end

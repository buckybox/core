class AddExtrasPackageIdToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :extras_package_id, :integer
  end
end

class AddOriginalPackageToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :original_package_id, :integer
    add_index :packages, :original_package_id
  end
end

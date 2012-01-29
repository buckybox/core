class AddPackingMethodToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :packing_method, :string
  end
end

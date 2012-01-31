class AddArchivedDataToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :archived_address, :text
    add_column :packages, :archived_order_quantity, :integer
    add_column :packages, :archived_box_name, :string
    add_column :packages, :archived_price_cents, :integer, :default => 0
    add_column :packages, :archived_currency, :string
    add_column :packages, :archived_customer_name, :string
  end
end

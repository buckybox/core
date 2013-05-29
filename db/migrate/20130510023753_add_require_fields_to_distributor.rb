class AddRequireFieldsToDistributor < ActiveRecord::Migration
  def change
    rename_column :distributors, :collect_phone_in_webstore, :collect_phone

    add_column :distributors, :require_phone, :boolean, null: false, default: false
    add_column :distributors, :require_address_1, :boolean, null: false, default: true
    add_column :distributors, :require_address_2, :boolean, null: false, default: false
    add_column :distributors, :require_suburb, :boolean, null: false, default: false
    add_column :distributors, :require_city, :boolean, null: false, default: false
  end
end

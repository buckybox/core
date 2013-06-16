class AddWebstoreFlagToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :via_webstore, :boolean, default: false
  end
end

class DefaultActiveToFalseForOrders < ActiveRecord::Migration
  def up
    change_column :orders, :active, :boolean, :default => false, :null => false
  end

  def down
    change_column :orders, :active, :boolean, :default => true, :null => false
  end
end

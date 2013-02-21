class ChangeCustomerCanSendEmailDefault < ActiveRecord::Migration
  def up
    change_column :distributors, :customer_can_remove_orders, :boolean, :default => :true
    change_column :distributors, :send_email, :boolean, :default => :true
  end

  def down
    change_column :distributors, :customer_can_remove_orders, :boolean, :default => :false
    change_column :distributors, :send_email, :boolean, :default => :false
  end
end

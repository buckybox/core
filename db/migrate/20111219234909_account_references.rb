class AccountReferences < ActiveRecord::Migration
  def up
    remove_column :orders, :customer_id
    remove_column :orders, :distributor_id
  end

  def down
    add_column :orders, :customer_id, :integer
    add_column :orders, :distributor_id, :integer
    Order.all.each do |o|
      o.update_attribute(:customer_id, o.account.customer_id)
      o.update_attribute(:distributor_id, o.account.customer.distributor_id)
    end
  end
end

class AccountReferences < ActiveRecord::Migration
  class Order < ActiveRecord::Base; end
  class Account < ActiveRecord::Base; end
  class Customer < ActiveRecord::Base; end

  def up
    remove_index :orders, :distributor_id
    remove_index :orders, :customer_id
    remove_column :orders, :distributor_id
    remove_column :orders, :customer_id
  end

  def down
    add_column :orders, :customer_id, :integer
    add_column :orders, :distributor_id, :integer
    add_index :orders, :customer_id
    add_index :orders, :distributor_id

    Order.reset_column_information
    Account.reset_column_information
    Customer.reset_column_information

    Order.all.each do |order|
      account = Account.find_by_id(order.account_id)

      if account
        customer = Customer.find_by_id(account.customer_id)

        if customer
          order.update_attributes!(customer_id:customer.id, distributor_id:customer.distributor_id)
        end
      end
    end
  end
end

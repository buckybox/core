class AddDistributorToWebstoreOrder < ActiveRecord::Migration
  class WebstoreOrder < ActiveRecord::Base; end
  class Account < ActiveRecord::Base; end
  class Customer < ActiveRecord::Base; end

  def up
    WebstoreOrder.reset_column_information
    Account.reset_column_information
    Customer.reset_column_information

    add_column :webstore_orders, :distributor_id, :integer

    WebstoreOrder.all.each do |webstore_order|
      account_id = webstore_order.read_attribute(:account_id)
      account = Account.find_by_id(account_id)

      if account
        customer_id = account.read_attribute(:customer_id)
        customer = Customer.find_by_id(customer_id)

        if customer
          distributor_id = customer.read_attribute(:distributor_id)
          webstore_order.update_column(:distributor_id, distributor_id)
        end
      end
    end
  end

  def down
    remove_column :webstore_orders, :distributor_id
  end
end

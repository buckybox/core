class MovePhoneFromCustomerToAddress < ActiveRecord::Migration
  class Customer < ActiveRecord::Base; end
  class Address < ActiveRecord::Base; end

  def up
    Customer.reset_column_information
    Address.reset_column_information

    add_column :addresses, :phone, :string

    Customer.all.each do |customer|
      address = Address.find_by_customer_id(customer.id)

      if address
        value = customer.read_attribute(:phone)
        address.update_attribute(:phone, value)
      end
    end

    remove_column :customers, :phone
  end

  def down
    Customer.reset_column_information
    Address.reset_column_information

    add_column :customers, :phone, :string

    Address.all.each do |address|
      customer = Customer.find_by_id(address.customer_id)

      if customer
        value = address.read_attribute(:phone)
        customer.update_attribute(:phone, value)
      end
    end

    remove_column :addresses, :phone
  end
end

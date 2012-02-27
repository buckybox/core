class ChangeCustomerNumbers < ActiveRecord::Migration
  class Distributor < ActiveRecord::Base; end
  class Customer < ActiveRecord::Base; end

  def up
    Customer.reset_column_information

    remove_column :customers, :number
    add_column :customers, :number, :integer

    Distributor.all.each do |distributor|
      count = 1

      Customer.find_all_by_distributor_id(distributor.id).each do |customer|
        customer.update_attribute(:number, count)
        count += 1
      end
    end
  end

  def down
    change_column :customers, :number, :string
  end
end

class DowncaseEmail < ActiveRecord::Migration
  class Distributor < ActiveRecord::Base; end
  class Customer < ActiveRecord::Base; end

  def up
    Distributor.reset_column_information
    Customer.reset_column_information

    Distributor.all.each do |distributor|
      distributor.update_attributes!(email: distributor.email.downcase)
    end

    Customer.all.each do |customer|
      customer.update_attributes!(email: customer.email.downcase)
    end
  end

  def down
  end
end

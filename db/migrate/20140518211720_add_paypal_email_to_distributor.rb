class AddPaypalEmailToDistributor < ActiveRecord::Migration
  class Distributor < ActiveRecord::Base; end

  def change
    add_column :distributors, :paypal_email, :string

    Distributor.update_all("paypal_email = email")
  end
end

class AddPaymentPaypalToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :payment_paypal, :boolean, null: false, default: false
  end
end

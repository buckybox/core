class AddPaymentMethodToWebstoreOrder < ActiveRecord::Migration
  def change
    add_column :webstore_orders, :payment_method, :string
  end
end

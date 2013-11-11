class AddDefaultPaymentMethodToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :default_payment_method, :string
  end
end

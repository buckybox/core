class AddDiscountToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :discount, :decimal, default: 0, null: false
  end
end

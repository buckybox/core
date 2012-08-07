class AddSpecialOrderPreferenceToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :special_order_preference, :text
  end
end

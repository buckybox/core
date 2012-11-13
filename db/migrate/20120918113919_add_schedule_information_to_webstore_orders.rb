class AddScheduleInformationToWebstoreOrders < ActiveRecord::Migration
  def change
    add_column :webstore_orders, :schedule, :text
    add_column :webstore_orders, :frequency, :string
    add_column :webstore_orders, :extras_one_off, :boolean
  end
end

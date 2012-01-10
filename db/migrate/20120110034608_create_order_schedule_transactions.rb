class CreateOrderScheduleTransactions < ActiveRecord::Migration
  def change
    create_table :order_schedule_transactions do |t|
      t.references :order
      t.text :schedule
      t.references :delivery

      t.timestamps
    end
    add_index :order_schedule_transactions, :order_id
    add_index :order_schedule_transactions, :delivery_id
  end
end

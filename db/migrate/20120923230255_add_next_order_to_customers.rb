class AddNextOrderToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :next_order_id, :integer
    add_column :customers, :next_order_occurrence_date, :date
  end
end

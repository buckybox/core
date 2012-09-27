class AddNextOrderToCustomers < ActiveRecord::Migration
  def up
    add_column :customers, :next_order_id, :integer
    add_column :customers, :next_order_occurrence_date, :date
    
    Customer.reset_column_information
    Distributor.find_each do |distributor|
      distributor.update_next_occurrence_caches
    end
  end
  
  def down
    remove_column :customers, :next_order_id
    remove_column :customers, :next_order_occurrence_date
  end
end

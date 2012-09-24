class AddNextOrderToCustomers < ActiveRecord::Migration
  def up
    add_column :customers, :next_order_id, :integer
    add_column :customers, :next_order_occurrence_date, :date
    
    Customer.reset_column_information
    Customer.find_each do |c|
      raise "That should have succeeded" unless c.update_next_occurrence.save
    end
  end
  
  def down
    remove_column :customers, :next_order_id
    remove_column :customers, :next_order_occurrence_date
  end
end

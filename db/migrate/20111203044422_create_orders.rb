class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.references :distributor
      t.references :box
      t.references :customer
      t.integer :quantity, :default => 1, :null => false
      t.text :likes
      t.text :dislikes
      t.string :frequency, :default => 'single', :null => false
      t.boolean :completed, :default => false, :null => false

      t.timestamps
    end
    add_index :orders, :distributor_id
    add_index :orders, :box_id
    add_index :orders, :customer_id
  end
end

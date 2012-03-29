class CreateOrderExtras < ActiveRecord::Migration
  def change
    create_table :order_extras do |t|
      t.integer :order_id
      t.integer :extra_id
      t.integer :count

      t.timestamps
    end
  end
end

class CreateStockItems < ActiveRecord::Migration
  def change
    create_table :stock_items do |t|
      t.references :distributor
      t.string :name

      t.timestamps
    end
    add_index :stock_items, :distributor_id
  end
end

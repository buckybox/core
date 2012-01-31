class CreateDeliveryLists < ActiveRecord::Migration
  def change
    create_table :delivery_lists do |t|
      t.references :distributor
      t.date :date

      t.timestamps
    end
    add_index :delivery_lists, :distributor_id
  end
end

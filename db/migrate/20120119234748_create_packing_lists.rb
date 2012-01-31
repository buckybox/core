class CreatePackingLists < ActiveRecord::Migration
  def change
    create_table :packing_lists do |t|
      t.references :distributor
      t.date :date

      t.timestamps
    end
    add_index :packing_lists, :distributor_id
  end
end

class CreateExclusions < ActiveRecord::Migration
  def change
    create_table :exclusions do |t|
      t.references :order
      t.references :line_item

      t.timestamps
    end
    add_index :exclusions, :order_id
    add_index :exclusions, :line_item_id
  end
end

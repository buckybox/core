class CreateSubstitutions < ActiveRecord::Migration
  def change
    create_table :substitutions do |t|
      t.references :order
      t.references :line_item

      t.timestamps
    end
    add_index :substitutions, :order_id
    add_index :substitutions, :line_item_id
  end
end

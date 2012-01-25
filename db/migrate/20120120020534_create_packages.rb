class CreatePackages < ActiveRecord::Migration
  def change
    create_table :packages do |t|
      t.references :packing_list
      t.integer :position
      t.string :status

      t.timestamps
    end
    add_index :packages, :packing_list_id
  end
end

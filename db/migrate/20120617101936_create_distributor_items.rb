class CreateDistributorItems < ActiveRecord::Migration
  def change
    create_table :distributor_items do |t|
      t.references :distributor
      t.string :name

      t.timestamps
    end
    add_index :distributor_items, :distributor_id
  end
end

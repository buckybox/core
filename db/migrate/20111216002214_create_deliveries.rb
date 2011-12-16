class CreateDeliveries < ActiveRecord::Migration
  def change
    create_table :deliveries do |t|
      t.references :order
      t.date :date
      t.timestamps
    end
  end
end

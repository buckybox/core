class CreateExtras < ActiveRecord::Migration
  def change
    create_table :extras do |t|
      t.string :title
      t.string :unit
      t.integer :distributor_id
      t.integer :price_cents

      t.timestamps
    end
  end
end

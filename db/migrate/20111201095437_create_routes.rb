class CreateRoutes < ActiveRecord::Migration
  def change
    create_table :routes do |t|
      t.references :distributor
      t.string :name
      t.boolean :monday, :default => false, :null => false
      t.boolean :tuesday, :default => false, :null => false
      t.boolean :wednesday, :default => false, :null => false
      t.boolean :thursday, :default => false, :null => false
      t.boolean :friday, :default => false, :null => false
      t.boolean :saturday, :default => false, :null => false
      t.boolean :sunday, :default => false, :null => false

      t.timestamps
    end
    add_index :routes, :distributor_id
  end
end

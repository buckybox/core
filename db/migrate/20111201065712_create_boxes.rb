class CreateBoxes < ActiveRecord::Migration
  def change
    create_table :boxes do |t|
      t.references :distributor
      t.string :name
      t.text :description
      t.boolean :likes, :default => false, :null => false
      t.boolean :dislikes, :default => false, :null => false
      t.integer :price_cents, :default => 0, :null => false
      t.string :currency, :string
      t.boolean :available_single, :default => false, :null => false
      t.boolean :available_weekly, :default => false, :null => false
      t.boolean :available_fourtnightly, :default => false, :null => false

      t.timestamps
    end
  end
end

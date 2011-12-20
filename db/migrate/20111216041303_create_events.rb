class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :distributor_id, :null => false 
      t.string :event_category, :null => false 
      t.integer :invoice_id, :null => true
      t.integer :reconciliation_id, :null => true
      t.integer :transaction_id, :null => true
      t.boolean :dismissed, :null => false, :default => false

      t.timestamps
    end

    add_index :events, :distributor_id
  end
end

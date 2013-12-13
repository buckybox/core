class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.references :customer, null: false
      t.text :action, null: false

      t.timestamps
    end

    add_index :activities, :customer_id
  end
end

class CreateCustomerCheckouts < ActiveRecord::Migration
  def change
    create_table :customer_checkouts do |t|
      t.integer :distributor_id
      t.integer :customer_id

      t.timestamps
    end
  end
end

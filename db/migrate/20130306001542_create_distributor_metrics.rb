class CreateDistributorMetrics < ActiveRecord::Migration
  def change
    add_column :distributors, :last_seen_at, :timestamp

    create_table :distributor_metrics do |t|
      t.integer :distributor_id
      t.integer :distributor_logins
      t.integer :new_customers
      t.integer :deliveries_completed
      t.integer :customer_payments
      t.integer :webstore_checkouts
      t.integer :customer_logins

      t.timestamps
    end
  end
end

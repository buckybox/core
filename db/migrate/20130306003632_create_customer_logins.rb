class CreateCustomerLogins < ActiveRecord::Migration
  def change
    create_table :customer_logins do |t|
      t.integer :distributor_id
      t.integer :customer_id

      t.timestamps
    end
  end
end

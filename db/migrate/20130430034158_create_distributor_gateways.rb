class CreateDistributorGateways < ActiveRecord::Migration
  def change
    create_table :distributor_gateways do |t|
      t.integer :distributor_id
      t.integer :gateway_id

      t.text :encrypted_login
      t.text :encrypted_login_salt
      t.text :encrypted_login_iv
      t.text :encrypted_password
      t.text :encrypted_password_salt
      t.text :encrypted_password_iv

      t.timestamps
    end
  end
end

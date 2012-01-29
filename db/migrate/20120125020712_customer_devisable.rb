class CustomerDevisable < ActiveRecord::Migration
  def up
    add_column :customers, "encrypted_password", :string, :limit => 128, :default => "",     :null => false
    add_column :customers, "reset_password_token", :string   
    add_column :customers, "reset_password_sent_at", :datetime 
    add_column :customers, "remember_created_at", :datetime 
    add_column :customers, "sign_in_count", :integer, :default => 0
    add_column :customers, "current_sign_in_at", :datetime 
    add_column :customers, "last_sign_in_at", :datetime 
    add_column :customers, "current_sign_in_ip", :string   
    add_column :customers, "last_sign_in_ip", :string   
    add_column :customers, "password_salt", :string   
    add_column :customers, "confirmation_token", :string   
    add_column :customers, "confirmed_at", :datetime 
    add_column :customers, "confirmation_sent_at", :datetime 
    add_column :customers, "failed_attempts", :integer, :default => 0
    add_column :customers, "unlock_token", :string   
    add_column :customers, "locked_at", :datetime 
    add_column :customers, "authentication_token", :string   

    add_index :customers, :email,                :unique => true
    add_index :customers, :reset_password_token, :unique => true
    add_index :customers, :confirmation_token,   :unique => true
    add_index :customers, :unlock_token,         :unique => true
    add_index :customers, :authentication_token, :unique => true
  end

  def down
    remove_index :customers, :column => :authentication_token
    remove_index :customers, :column => :unlock_token
    remove_index :customers, :column => :confirmation_token
    remove_index :customers, :column => :reset_password_token
    remove_index :customers, :column => :email

    remove_column :customers, "authentication_token"
    remove_column :customers, "locked_at"
    remove_column :customers, "unlock_token"
    remove_column :customers, "failed_attempts"
    remove_column :customers, "confirmation_sent_at"
    remove_column :customers, "confirmed_at"
    remove_column :customers, "confirmation_token"
    remove_column :customers, "password_salt"
    remove_column :customers, "last_sign_in_ip"
    remove_column :customers, "current_sign_in_ip"
    remove_column :customers, "last_sign_in_at"
    remove_column :customers, "current_sign_in_at"
    remove_column :customers, "sign_in_count"
    remove_column :customers, "remember_created_at"
    remove_column :customers, "reset_password_sent_at"
    remove_column :customers, "reset_password_token"
    remove_column :customers, "encrypted_password"
  end
end

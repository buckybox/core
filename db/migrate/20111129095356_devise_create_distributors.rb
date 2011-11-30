class DeviseCreateDistributors < ActiveRecord::Migration
  def change
    create_table(:distributors) do |t|
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable

      t.encryptable
      t.confirmable
      t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      t.token_authenticatable


      t.timestamps
    end

    add_index :distributors, :email,                :unique => true
    add_index :distributors, :reset_password_token, :unique => true
    add_index :distributors, :confirmation_token,   :unique => true
    add_index :distributors, :unlock_token,         :unique => true
    add_index :distributors, :authentication_token, :unique => true
  end

end

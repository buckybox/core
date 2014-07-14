class LockMpcheapAccount < ActiveRecord::Migration
  def up
    Distributor.find(55).lock_access!(send_instructions: false)
  end

  def down
    Distributor.find(55).unlock_access!
  end
end

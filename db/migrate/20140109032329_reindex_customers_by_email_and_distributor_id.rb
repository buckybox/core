class ReindexCustomersByEmailAndDistributorId < ActiveRecord::Migration
  def change
    remove_index :customers, :email
    add_index :customers, [:email, :distributor_id], unique: true
  end
end

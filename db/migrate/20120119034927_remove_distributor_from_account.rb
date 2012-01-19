class RemoveDistributorFromAccount < ActiveRecord::Migration
  def up
    remove_column :accounts, :distributor_id
  end

  def down
    add_column :accounts, :distributor_id, :integer
  end
end

class AddAccountReferenceToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :account_id, :integer
    add_index :orders, :account_id
  end
end

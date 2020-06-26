class RemoveUnconfirmedEmail < ActiveRecord::Migration
  def change
    remove_column :distributors, :unconfirmed_email
  end
end

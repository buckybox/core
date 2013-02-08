class ChangeCreditLimit < ActiveRecord::Migration
  def change
    rename_column :customers, :override_balance_threshold_cents, :balance_threshold_cents
    remove_column :customers, :override_default_balance_threshold
  end
end

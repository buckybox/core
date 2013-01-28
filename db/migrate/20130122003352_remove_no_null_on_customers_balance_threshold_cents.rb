class RemoveNoNullOnCustomersBalanceThresholdCents < ActiveRecord::Migration
  def up
    change_column :customers, :balance_threshold_cents, :integer, null: true
  end

  def down
    change_column :customers, :balance_threshold_cents, :integer, null: false
  end
end

class RemoveDefaultOnCustomersBalanceThresholdCents < ActiveRecord::Migration
  def up
    change_column :customers, :balance_threshold_cents, :integer, null: false, default: nil
    change_column_default(:customers, :balance_threshold_cents, nil)
  end

  def down
    change_column :customers, :balance_threshold_cents, :integer, null: true, default: 0
  end
end

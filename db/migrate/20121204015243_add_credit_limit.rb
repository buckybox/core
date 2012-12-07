class AddCreditLimit < ActiveRecord::Migration
  def change
    add_column :distributors, :default_balance_threshold_cents, :integer, default: 0
    add_column :customers, :balance_threshold_cents, :integer, default: 0
    add_column :customers, :status_halted, :boolean, default: false
  end
end

class AddCreditLimit < ActiveRecord::Migration
  def change
    add_column :distributors, :default_credit_limit_cents, :integer, default: 0
    add_column :customers, :credit_limit_cents, :integer, default: 0
    add_column :customers, :status_halted, :boolean, default: false
  end
end

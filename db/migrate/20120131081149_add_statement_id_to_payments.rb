class AddStatementIdToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :statement_id, :integer
  end
end

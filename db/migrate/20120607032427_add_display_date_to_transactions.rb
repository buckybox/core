class AddDisplayDateToTransactions < ActiveRecord::Migration
  class Transaction < ActiveRecord::Base; end

  def up
    Transaction.reset_column_information

    add_column :transactions, :display_date, :date

    Transaction.all.each { |t| t.update_attribute(:display_date, t.created_at.to_date) }
  end

  def down
    remove_column :transactions, :display_date
  end
end

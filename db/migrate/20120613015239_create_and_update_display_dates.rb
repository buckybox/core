class CreateAndUpdateDisplayDates < ActiveRecord::Migration
  def up
    change_column :transactions, :display_date, :datetime
    change_column :payments, :payment_date, :datetime

    rename_column :transactions, :display_date, :display_time
    rename_column :payments, :payment_date, :display_time

    add_column :deductions, :display_time, :datetime
  end

  def down
    remove_column :deductions, :display_time

    rename_column :payments, :display_time, :payment_date
    rename_column :transactions, :display_time, :display_date

    change_column :payments, :payment_date, :date
    change_column :transactions, :display_date, :date
  end
end

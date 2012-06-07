class AddPaymentDateToPayments < ActiveRecord::Migration
  class Payment < ActiveRecord::Base; end

  def up
    Payment.reset_column_information

    add_column :payments, :payment_date, :date

    Payment.all.each { |p| p.update_attribute(:payment_date, p.created_at.to_date) }
  end

  def down
    remove_column :payments, :payment_date
  end
end

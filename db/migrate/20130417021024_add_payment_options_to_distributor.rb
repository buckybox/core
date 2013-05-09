class AddPaymentOptionsToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :payment_cash_on_delivery, :boolean, default: true
    add_column :distributors, :payment_bank_deposit, :boolean, default: true
    add_column :distributors, :payment_credit_card, :boolean, default: false

    Distributor.update_all("payment_cash_on_delivery = 't', payment_bank_deposit = 't', payment_credit_card = 'f'")
  end
end

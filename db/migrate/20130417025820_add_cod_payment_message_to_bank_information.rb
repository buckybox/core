class AddCodPaymentMessageToBankInformation < ActiveRecord::Migration
  def change
    add_column :bank_information, :cod_payment_message, :text
  end
end

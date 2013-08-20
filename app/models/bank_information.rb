class BankInformation < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :distributor, :name, :account_name, :account_number, :customer_message, :bsb_number, :cod_payment_message

  validates_presence_of :distributor, :name, :account_name, :account_number, :customer_message, :bsb_number
end

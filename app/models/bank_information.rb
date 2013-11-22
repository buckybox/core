class BankInformation < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :distributor, :name, :account_name, :account_number, :customer_message, :cod_payment_message

  validates_presence_of :distributor
  validates_presence_of :name, :account_name, :account_number, if: -> { distributor.payment_bank_deposit }

  delegate :country, to: :distributor
end

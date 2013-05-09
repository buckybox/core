class CreditCardTransaction < ActiveRecord::Base
  attr_accessible :account_id, :action, :amount, :distributor_id, :message, :params, :reference, :success, :test

  belongs_to :account
  belongs_to :distributor

  serialize :params
end

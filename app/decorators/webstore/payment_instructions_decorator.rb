require 'draper'
require_relative '../../models/webstore/payment_options'
require_relative '../../models/money_display'

class Webstore::PaymentInstructionsDecorator < Draper::Decorator
  delegate_all

  def order_price
    price = MoneyDisplay.new(object.order_price)
    price.negative
  end

  def closing_balance
    MoneyDisplay.new(object.closing_balance)
  end

  def amount_due
    MoneyDisplay.new(object.amount_due)
  end
end

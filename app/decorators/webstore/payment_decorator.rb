require 'draper'
require_relative '../money_decorator'

class Webstore::PaymentDecorator < Draper::Decorator
  delegate_all

  def order_price
    price = MoneyDecorator.decorate(object.order_price)
    price.negative
  end

  def closing_balance
    MoneyDecorator.decorate(object.closing_balance)
  end

  def amount_due
    MoneyDecorator.decorate(object.amount_due)
  end
end

class Webstore::PaymentInstructions < Webstore::Form
  def initialize(cart)
    @cart = cart
  end

  def current_balance
    #(current_customer ? current_customer.account.balance : Money.new(0))
    MoneyDisplay.new(Money.new(0))
  end

  def order_price
    #order.order_price(current_customer)
    MoneyDisplay.new(Money.new(0)).negative
  end

  def closing_balance
    #current_balance + order_price)
    MoneyDisplay.new(Money.new(0))
  end

  def existing_customer?
    #current_customer && current_customer.persisted?
    true
  end

private

  attr_reader :cart
end

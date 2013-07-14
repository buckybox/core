module Webstore::PaymentInstructions
  def payment_method
    #'value'
    customer.payment_method
  end

  def payment_required?
    !closing_balance.positive?
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
    #@current_balance = (current_customer ? current_customer.account.balance : Money.new(0))
    #@closing_balance = @current_balance - @order_price
    MoneyDisplay.new(Money.new(0))
  end

  def amount_due
    #MoneyDisplay.new(@amount_due).negative
    closing_balance * -1
  end
end

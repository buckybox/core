class Webstore::PaymentInstructions
  def initialize(args)
    @customer = args[:customer]
    @order    = args[:order]
  end

  def payment_method
    order.payment_method
  end

  def payment_required?
    closing_balance.negative?
  end

  def current_balance
    customer.account_balance
  end

  def order_price
    order.total
  end

  def closing_balance
    current_balance - order_price
  end

  def amount_due
    -closing_balance
  end

private

  attr_reader :customer
  attr_reader :order
end

class OrderPrice
  def self.discounted(price, customer_discount = nil)
    return price if customer_discount.nil? # Convenience so we don't have to check all over app for nil

    customer_discount = customer_discount.discount if customer_discount.is_a?(Customer)

    price * (1 - customer_discount)
  end

  def self.individual(box_price, delivery_service_fee, customer_discount = nil)
    box_price = box_price.price if box_price.is_a?(Box)
    delivery_service_fee = delivery_service_fee.fee if delivery_service_fee.is_a?(DeliveryService)
    customer_discount = customer_discount.discount if customer_discount.is_a?(Customer)

    total_price = box_price + delivery_service_fee

    customer_discount ? discounted(total_price, customer_discount) : total_price
  end

  def self.extras_price(order_extras, customer_discount = nil)
    customer_discount = customer_discount.discount if customer_discount.is_a?(Customer)

    total_price = order_extras.map do |order_extra|
      order_extra = order_extra.to_hash unless order_extra.is_a? Hash

      price = if order_extra[:price_cents]
        order_extra[:price_cents] / 100.0 # NOTE: legacy support for archived packages
      else
        order_extra[:price]
      end

      price * order_extra[:count]
    end.sum

    customer_discount ? discounted(total_price, customer_discount) : total_price
  end

  def self.without_delivery_fee(price, quantity, extras_price, has_extras)
    result = price
    result = result * quantity if quantity
    result += extras_price if has_extras
    result
  end

  def self.with_delivery_fee(price, delivery_fee)
    if delivery_fee && delivery_fee > 0
      price + delivery_fee
    else
      price
    end
  end
end

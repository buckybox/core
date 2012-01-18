module OrdersHelper
  def order_address(order)
    a = order.address

    address = [a.address_1]
    address << a.address_2 unless a.address_2.blank?
    address << a.suburb

    return address.join(', ').html_safe
  end
end

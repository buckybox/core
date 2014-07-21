module Distributor::BoxesHelper
  def box_collection(customer, options = {})
    boxes = customer.distributor.boxes

    if options[:with_price]
      delivery_service_fee = customer.delivery_service.fee
      currency = customer.distributor.currency

      boxes = boxes.not_hidden if options[:no_hidden_boxes]
      boxes << options[:ensure_box] if options[:ensure_box] && !boxes.include?(options[:ensure_box])
      boxes = boxes.sort_by(&:name)
      boxes = boxes.map do |box|
        box_price = OrderPrice.discounted(box.price, customer).with_currency(currency)

        text = "#{box.name} - #{box_price}"
        text << " + #{delivery_service_fee.with_currency(currency)} delivery" if delivery_service_fee > 0

        [text, box.id]
      end
    end

    boxes
  end

  def customers_box_collection(customer, order, options = {})
    box_collection(customer, options.merge(no_hidden_boxes: true, ensure_box: @order.box))
  end
end

module Distributor::BoxesHelper
  def box_collection(customer, options = {})
    boxes = customer.distributor.boxes

    if options[:with_price]
      delivery_service = customer.delivery_service

      boxes = boxes.not_hidden if options[:no_hidden_boxes]
      boxes << options[:ensure_box] if options[:ensure_box] && !boxes.include?(options[:ensure_box])
      boxes = boxes.sort_by(&:name)
      boxes = boxes.map do |box|
        element = []

        if customer.separate_bucky_fee?
          text = "#{box.name} - (#{OrderPrice.individual(box, delivery_service, customer)} + #{customer.consumer_delivery_fee} Fee)"
        else
          text = "#{box.name} - (#{OrderPrice.individual(box, delivery_service, customer)})"
        end

        text << " (#{box.extras_limit})" if options[:with_extras_limit]
        element << text
        element << box.id
        element
      end
    end

    return boxes
  end

  def customers_box_collection(customer, order, options = {})
    box_collection(customer, options.merge({no_hidden_boxes: true, ensure_box: @order.box}))
  end
end

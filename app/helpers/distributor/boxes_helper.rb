module Distributor::BoxesHelper
  def box_collection(customer, options = {})
    boxes = customer.distributor.boxes

    if options[:with_price]
      route = customer.route

      boxes = boxes.map do |box|
        ["#{box.name} - #{Package.calculated_price(box, route, customer).format}", box.id]
      end
    end

    return boxes
  end
end

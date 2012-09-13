module Distributor::BoxesHelper
  def box_collection(customer, options = {})
    boxes = customer.distributor.boxes

    if options[:with_price]
      route = customer.route

      boxes = boxes.map do |box|
        element = []
        text = "#{box.name} - #{Package.calculated_individual_price(box, route, customer).format}"
        text << " (#{box.extras_limit})" if options[:with_extras_limit]
        element << text
        element << box.id
        element
      end
    end

    return boxes
  end
end

module Distributor::BoxesHelper
  def option_status_for(option_value)
    status = option_value ? '&#x2714' : '&#10007'
    content_tag :span, status.html_safe, :class => "status status-#{option_value}"
  end

  def box_collection(distributor, options = {})
    boxes = distributor.boxes
    distributor.boxes.map { |b| ["#{b.name} - #{b.price.format}", b.id] } if options[:with_price]
  end
end

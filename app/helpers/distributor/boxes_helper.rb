module Distributor::BoxesHelper
  def box_collection(distributor, options = {})
    boxes = distributor.boxes
    distributor.boxes.map { |b| ["#{b.name} - #{b.price.format}", b.id] } if options[:with_price]
  end
end

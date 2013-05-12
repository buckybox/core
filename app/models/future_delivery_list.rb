class FutureDeliveryList
  attr_reader :date
  attr_reader :deliveries

  def initialize(date, deliveries)
    @date       = date
    @deliveries = deliveries
  end

  def ordered_deliveries(ids = nil)
    list_items = deliveries
    list_items = list_items.select { |item| ids.include?(item.id) } if ids
    list_items
  end
end

class FutureDeliveryList
  attr_reader :date
  attr_reader :deliveries

  def initialize(date, deliveries)
    @date       = date
    @deliveries = deliveries
  end
end

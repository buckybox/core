class Distributor::Setup

  def initialize(distributor, args = {})
    @distributor = distributor
  end

  def finished?
    has_delivery_services?
  end

  def progress
    done = has_delivery_services? ? 1.0 : 0.0
    (done / 1.0 * 100.0)
  end

  def progress_left
    100.0 - progress
  end

private

  attr_reader :distributor

  def has_delivery_services?
    !distributor.delivery_services.empty?
  end
end

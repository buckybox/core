class Distributor::Setup

  def initialize(distributor, args = {})
    @distributor = distributor
  end

  def finished?
    has_routes?
  end

  def progress
    done = has_routes? ? 1.0 : 0.0
    (done / 1.0 * 100.0)
  end

  def progress_left
    100.0 - progress
  end

private

  attr_reader :distributor

  def has_routes?
    !distributor.routes.empty?
  end
end

class Distributor::Setup

  def initialize(distributor, args = {})
    @distributor = distributor
  end

  def done?
    !distributor.routes.empty?
  end

private

  attr_reader :distributor
end

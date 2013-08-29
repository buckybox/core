class Distributor::Setup

  STEPS = [
    "delivery_services",
    "boxes",
    "customers",
  ].freeze

  def initialize(distributor, args = {})
    @distributor = distributor
  end

  def finished?
    progress == 100.0
  end

  def total_steps
    STEPS.size
  end

  def steps_done
    STEPS.map { |step| send("has_#{step}?") }.count(true)
  end

  def progress
    percentage = steps_done.to_f / total_steps.to_f
    percentage * 100.0
  end

  def progress_left
    100.0 - progress
  end

private

  attr_reader :distributor

  def has_delivery_services?
    !distributor.delivery_services.to_a.empty?
  end

  def has_boxes?
    !distributor.boxes.to_a.empty?
  end

  def has_customers?
    !distributor.customers.to_a.empty?
  end
end

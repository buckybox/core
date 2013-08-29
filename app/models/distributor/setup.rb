class Distributor::Setup

  STEPS = [
    "delivery_services",
    "boxes",
  ].freeze

  def initialize(distributor, args = {})
    @distributor = distributor
  end

  def finished?
    progress == 100.0
  end

  def progress
    percentage = steps_done / total_steps
    percentage * 100.0
  end

  def progress_left
    100.0 - progress
  end

private

  attr_reader :distributor

  def total_steps
    STEPS.size.to_f
  end

  def steps_done
    STEPS.map { |step| send("has_#{step}?") }.count(true).to_f
  end

  def has_delivery_services?
    !distributor.delivery_services.to_a.empty?
  end

  def has_boxes?
    !distributor.boxes.to_a.empty?
  end
end

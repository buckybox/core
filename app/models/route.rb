class Route < ActiveRecord::Base
  include Bucky

  belongs_to :distributor

  has_many :deliveries, dependent: :destroy
  has_many :orders, through: :deliveries
  has_many :customers
  has_one :schedule_rule, as: :scheduleable, inverse_of: :scheduleable, autosave: true

  monetize :fee_cents

  attr_accessible :distributor, :name, :fee, :area_of_service, :estimated_delivery_time, :schedule_rule_attributes
  accepts_nested_attributes_for :schedule_rule

  validates_presence_of :distributor_id, :name, :fee, :area_of_service, :estimated_delivery_time, :schedule_rule
  validate :schedule_rule_has_at_least_one_day

  default_scope order(:name)

  delegate :local_time_zone, to: :distributor, allow_nil: true
  
  delegate :includes?, :delivery_day_numbers, to: :schedule_rule, allow_nil: true

  after_initialize :set_default_schedule_rule
  
  def set_default_schedule_rule
    self.schedule_rule ||= ScheduleRule.weekly if new_record?
  end

  def self.default_route(distributor)
    distributor.routes.first # For now the first one is the default
  end

  def self.default_route_on(distributor, time)
    distributor.routes.find { |r| r.delivers_on?(time) }
  end

  def name_days_and_fee
    days = delivery_days.map { |d| d.to_s.titleize[0..2] }

    result = name.titleize
    result += " (#{days.join(', ')}) "
    result += fee.format

    return result
  end

  def next_run
    schedule_rule.next_occurrence
  end

  def delivers_on?(time)
    schedule_rule.occurs_on?(time.to_time)
  end

  def future_orders
    Order.for_route_read_only(self)
  end
  
  def schedule_changed(schedule_rule)
    schedule_rule.deleted_day_numbers.each do |day|
      future_orders.active.each do |order|
        order.deactivate_for_day!(day)
      end
    end
  end

  private

  def schedule_rule_has_at_least_one_day
    unless schedule_rule.has_at_least_one_day?
      errors[:base] << "You must select at least one day for the route."
    end
  end

  # To support the ice_cube -> flux_cap migration
  def create_schedule_rule
    day_booleans = [sunday, monday, tuesday, wednesday, thursday, friday, saturday]
    days = day_booleans.each_with_index.collect { |bool, index|
      bool ? ScheduleRule::DAYS[index] : nil
    }.compact

    distributor.use_local_time_zone do
      self.schedule_rule = ScheduleRule.weekly(created_at.to_date, days)
    end
  end
end

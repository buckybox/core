class Route < ActiveRecord::Base
  include Bucky

  belongs_to :distributor

  has_many :deliveries, dependent: :destroy
  has_many :orders, through: :deliveries
  has_many :customers
  has_many :route_schedule_transactions, autosave: true

  composed_of :fee,
    class_name: "Money",
    mapping: [%w(fee_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  schedule_for :schedule

  attr_accessible :distributor, :name, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday, :fee

  validates_presence_of :distributor_id, :name, :schedule, :fee
  validate :at_least_one_day_is_selected

  before_validation :create_schedule
  before_save :record_schedule_change, if: :schedule_changed?
  before_save :update_order_schedules, if: :schedule_changed?

  default_scope order(:name)

  DAYS = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]

  delegate :local_time_zone, to: :distributor, allow_nil: true

  def self.default_route(distributor)
    distributor.routes.first # For now the first one is the default
  end

  def next_run
    schedule.next_occurrence
  end

  def delivery_days
    DAYS.select { |day| self[day] }
  end

  def delivery_day_numbers(days=delivery_days)
    days.collect { |day| DAYS.index(day)}
  end

  def future_orders
    Order.for_route_read_only(self)
  end

  protected

  def at_least_one_day_is_selected
    unless [monday, tuesday, wednesday, thursday, friday, saturday, sunday].any?
      errors[:base] << "You must select at least one day for the route."
    end
  end

  def create_schedule
    recurrence_rule = IceCube::Rule.weekly.day(*delivery_days)
    new_schedule = Bucky::Schedule.new(Time.current.beginning_of_day)
    new_schedule.add_recurrence_rule(recurrence_rule)
    self.schedule = new_schedule
  end

  def update_order_schedules
    deleted_day_numbers.each do |day|
      future_orders.active.each do |order|
        order.deactivate_for_day!(day)
      end
    end
  end

  def deleted_days
    DAYS.select{|day| self.send("#{day.to_s}_was") && !self.send(day)}
  end

  def deleted_day_numbers(days=deleted_days)
    delivery_day_numbers(days)
  end

  def record_schedule_change
    route_schedule_transactions.build(route: self, schedule: self.schedule)
  end
end

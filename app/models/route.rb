class Route < ActiveRecord::Base
  include Bucky

  belongs_to :distributor

  has_many :deliveries, dependent: :destroy
  has_many :orders, through: :deliveries
  has_many :customers
  has_many :route_schedule_transactions

  composed_of :fee,
    class_name: "Money",
    mapping: [%w(fee_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  schedule_for :schedule

  attr_accessible :distributor, :name, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday, :fee

  validates_presence_of :distributor, :name, :schedule, :fee
  validate :at_least_one_day_is_selected

  before_validation :create_schedule
  before_validation :update_schedule, if: 'schedule_changed?'

  default_scope order(:name)

  DAYS = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]

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
    Route.delivery_day_numbers(days)
  end

  def self.delivery_day_numbers(delivery_days)
    delivery_days.collect { |day| DAYS.index(day)}
  end

  def future_orders
    # Using a join makes the returned models read-only, this is a work around
    order_ids = Order.where(customers: {route_id: id}).joins(:customer).collect(&:id)
    Order.where(["id in (?)", order_ids])
  end

  def local_time_zone
    distributor.local_time_zone
  end

  protected

  def at_least_one_day_is_selected
    unless [monday, tuesday, wednesday, thursday, friday, saturday, sunday].any?
      errors[:base] << "You must select at least one day for the route."
    end
  end

  def create_schedule
    recurrence_rule = IceCube::Rule.weekly.day(*delivery_days)
    new_schedule = Schedule.new(Time.current.beginning_of_day)
    new_schedule.add_recurrence_rule(recurrence_rule)
    self.schedule = new_schedule
  end

  def update_schedule
    track_schedule_change
    deleted_day_numbers.each do |day|
      future_orders.active.each do |order|
        order.remove_recurrence_day(day)
        order.remove_recurrence_times_on_day(day)
        order.deactivate if order.schedule_empty?
        order.save
      end
    end
  end

  def deleted_days
    DAYS.select{|day| self.send("#{day.to_s}_was") && !self.send(day)}
  end

  def deleted_day_numbers(days=deleted_days)
    delivery_day_numbers(days)
  end

  def track_schedule_change
    route_schedule_transactions.build(route: self, schedule: self.schedule)
  end
end

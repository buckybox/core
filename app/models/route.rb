class Route < ActiveRecord::Base
  include Bucky

  belongs_to :distributor

  has_many :deliveries, :dependent => :destroy
  has_many :orders, :through => :deliveries
  has_many :customers
  has_many :route_schedule_transactions

  composed_of :fee,
    :class_name => "Money",
    :mapping => [%w(fee_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  schedule_for :schedule

  attr_accessible :distributor, :name, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday, :fee

  validates_presence_of :distributor, :name, :schedule, :fee
  validate :at_least_one_day_is_selected

  before_validation :create_schedule
  before_save :record_schedule_change, :if => 'schedule_changed?'

  default_scope order(:name)

  def self.default_route(distributor)
    distributor.routes.first # For now the first one is the default
  end

  def next_run
    schedule.next_occurrence
  end

  def delivery_days
    [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday].select { |day| self[day] }
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

  def record_schedule_change
    route_schedule_transactions.build(route: self, schedule: self.schedule)
  end
end

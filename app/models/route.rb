class Route < ActiveRecord::Base
  include IceCube

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

  serialize :schedule, Hash

  attr_accessible :distributor, :name, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday, :fee

  validates_presence_of :distributor, :name, :schedule, :fee
  validate :at_least_one_day_is_selected

  before_validation :create_schedule
  before_save :update_schedule, :if => 'schedule_changed?'

  default_scope order(:name)

  DAYS = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

  def self.default_route(distributor)
    distributor.routes.first # For now the first one is the default
  end

  def schedule
    Schedule.from_hash(self[:schedule]) if self[:schedule]
  end

  def next_run
    schedule.next_occurrence
  end

  def delivery_days
    DAYS.select { |day| self[day] }
  end

  protected

  def at_least_one_day_is_selected
    unless [monday, tuesday, wednesday, thursday, friday, saturday, sunday].any?
      errors[:base] << "You must select at least one day for the route."
    end
  end

  def create_schedule
    recurrence_rule = Rule.weekly.day(*delivery_days)
    new_schedule = Schedule.new(Time.new.beginning_of_day)
    new_schedule.add_recurrence_rule(recurrence_rule)
    self.schedule = new_schedule.to_hash
  end

  def update_schedule
    track_schedule_change
    deleted_days.each do |day|
      orders.active.each do |order|
        
      end
    end
  end

  def deleted_days
    DAYS.select?{|day| self.send("#{day.to_s}_was") && !self.send(day)}
  end

  def track_schedule_change
    route_schedule_transactions.build(route: self, schedule: self.schedule)
  end
end

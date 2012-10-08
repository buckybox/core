class Route < ActiveRecord::Base
  include Bucky

  belongs_to :distributor

  has_many :deliveries, dependent: :destroy
  has_many :orders, through: :deliveries
  has_many :customers
  has_many :route_schedule_transactions, autosave: true
  belongs_to :schedule_rule

  monetize :fee_cents

  schedule_for :schedule

  attr_accessible :distributor, :name, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday,
    :fee, :area_of_service, :estimated_delivery_time

  validates_presence_of :distributor_id, :name, :schedule, :fee, :area_of_service, :estimated_delivery_time
  validate :at_least_one_day_is_selected

  before_validation :create_schedule
  before_save :update_order_schedules, if: :schedule_changed?
  before_save :record_schedule_change, if: :schedule_changed?

  default_scope order(:name)

  delegate :local_time_zone, to: :distributor, allow_nil: true

  def self.default_route(distributor)
    distributor.routes.first # For now the first one is the default
  end

  def self.default_route_on(distributor, time)
    distributor.routes.find { |r| r.delivers_on?(time) }
  end

  def self.delivery_day_numbers(delivery_days)
    delivery_days.collect { |day| Bucky::Schedule::DAYS.index(day)}
  end

  def name_days_and_fee
    days = delivery_days.map { |d| d.to_s.titleize[0..2] }

    result = name.titleize
    result += " (#{days.join(', ')}) "
    result += fee.format

    return result
  end

  def delivery_days
    Bucky::Schedule::DAYS.select { |day| self[day] }
  end

  def delivery_day_numbers(days = delivery_days)
    Route.delivery_day_numbers(days)
  end

  def runs_on(wday)
    wday = Bucky::Schedule::DAYS[wday] if wday.is_a?(Integer)
    wday = wday.downcase.to_sym if wday.is_a?(String)
    self[wday]
  end

  def next_run
    schedule.next_occurrence
  end

  def delivers_on?(time)
    schedule.occurs_on?(time.to_time)
  end

  def future_orders
    Order.for_route_read_only(self)
  end

  protected

  def start_time=(time)
    @start_time = time
  end

  def start_time
    @start_time || Time.current.beginning_of_day
  end

  def deleted_days
    Bucky::Schedule::DAYS.select{|day| self.send("#{day.to_s}_was") && !self.send(day)}
  end

  def deleted_day_numbers(days = deleted_days)
    delivery_day_numbers(days)
  end

  private

  def at_least_one_day_is_selected
    unless [monday, tuesday, wednesday, thursday, friday, saturday, sunday].any?
      errors[:base] << "You must select at least one day for the route."
    end
  end

  def create_schedule
    day_booleans = [sunday, monday, tuesday, wednesday, thursday, friday, saturday]
    days = day_booleans.each_with_index { |bool, index|
      bool ? ScheduleRule::DAYS[index] : nil
    }.compact

    distributor.use_local_time_zone do
      self.schedule_rule = ScheduleRule.weekly(start_time.to_date, days)
    end
  end

  def record_schedule_change
    route_schedule_transactions.build(route: self, schedule: self.schedule)
  end

  def update_order_schedules
    deleted_day_numbers.each do |day|
      future_orders.active.each do |order|
        order.deactivate_for_day!(day)
      end
    end
  end
end

class Order < ActiveRecord::Base
  include IceCube

  belongs_to :account
  belongs_to :box

  has_one :distributor, through: :box
  has_one :customer,    through: :account
  has_one :address,     through: :customer
  has_one :route,       through: :customer

  has_many :packages
  has_many :deliveries
  has_many :order_schedule_transactions

  scope :completed, where(completed: true)
  scope :active, where(active: true)

  acts_as_taggable
  serialize :schedule, Hash

  attr_accessible :box, :box_id, :account, :account_id, :quantity, :likes, :dislikes, :completed, :frequency, :schedule

  FREQUENCIES = %w( single weekly fortnightly monthly )

  validates_presence_of :box, :quantity, :frequency, :account, :schedule
  validates_numericality_of :quantity, greater_than: 0
  validates_inclusion_of :frequency, in: FREQUENCIES, message: "%{value} is not a valid frequency"

  before_save :activate, if: :just_completed?
  before_save :record_schedule_change, if: :schedule_changed?

  default_scope order('created_at DESC')

  scope :completed, where(completed: true)
  scope :active,    where(active: true)
  scope :inactive,  where(active: false)

  def self.create_schedule(start_time, frequency, days_by_number = nil)
    if frequency != 'single' && days_by_number.nil?
      raise(ArgumentError, "Unless it is a single order the schedule needs to specify days.")
    end

    schedule = Schedule.new(start_time)

    if frequency == 'single'
      schedule.add_recurrence_time(start_time)
    elsif frequency == 'monthly'
      monthly_days_hash = days_by_number.inject({}) { |hash, day| hash[day] = [1]; hash }

      recurrence_rule = Rule.monthly.day_of_week(monthly_days_hash)
      schedule.add_recurrence_rule(recurrence_rule)
    else
      if frequency == 'weekly'
        weeks_between_deliveries = 1
      elsif frequency == 'fortnightly'
        weeks_between_deliveries = 2
      end

      recurrence_rule = Rule.weekly(weeks_between_deliveries).day(*days_by_number)
      schedule.add_recurrence_rule(recurrence_rule)
    end

    return schedule
  end

  def self.deactivate_finished
    active.each do |order|
      if order.schedule.next_occurrence.nil?
        order.deactivate
        order.save
        CronLog.log("Deactivated order #{order.id}")
      end
    end
  end

  def price
    individual_price * quantity
  end

  def individual_price
    Package.calculated_price(box, route, customer)
  end

  def customer= cust
    self.account = cust.account
  end

  def just_completed?
    completed_changed? && completed?
  end

  def schedule
    Schedule.from_hash(self[:schedule]) if self[:schedule]
  end

  def schedule=(schedule)
    self[:schedule] = schedule.to_hash
  end

  def add_scheduled_delivery(delivery)
    s = self.schedule
    s.add_recurrence_time(delivery.date.to_time)
    self.schedule = s
  end

  def remove_scheduled_delivery(delivery)
    s = schedule
    time = schedule.recurrence_times.find{ |t| t.to_date == delivery.date }
    s.remove_recurrence_time(time)
    self.schedule = s
  end

  def remove_recurrence_day(day)
    recurrence_rule = schedule.recurrence_rules.first
    new_schedule = schedule

    if recurrence_rule.present?
      new_schedule.remove_recurrence_rule(recurrence_rule)
      interval = recurrence_rule.to_hash[:interval]
      days = nil

      rule = case recurrence_rule
      when IceCube::WeeklyRule
        days = recurrence_rule.to_hash[:validations][:day] || []

        Rule.weekly(interval).day(*(days - [day]))
      when IceCube::MonthlyRule
        days = recurrence_rule.to_hash[:validations][:day_of_week].keys || []

        monthly_days_hash = (days - [day]).inject({}) { |hash, day| hash[day] = [1]; hash }
        Rule.monthly(interval).day_of_week(monthly_days_hash)
      end

      if rule.present? && (days - [day]).present?
        new_schedule.add_recurrence_rule(rule)
        self.schedule = new_schedule.to_hash
      else
        self.schedule = {}
      end
    else
      nil
    end
  end

  def remove_recurrence_times_on_day(day)
    day = Route::DAYS[day] if day.is_a?(Integer) && day.between?(0, 6)
    new_schedule = schedule
    schedule.recurrence_times.each do |recurrence_time|
      if recurrence_time.send("#{day}?") # recurrence_time.monday? for example
        new_schedule.remove_recurrence_time(recurrence_time)
      end
    end
    self.schedule = new_schedule.to_hash
  end

  def future_deliveries(end_date)
    results = []

    schedule.occurrences_between(Time.now, end_date).each do |occurence|
      results << { date: occurence.to_date, price: self.price, description: "Delivery for order ##{id}"}
    end

    return results
  end

  def string_pluralize
    box_name = box.name
    "#{quantity || 0} " + ((quantity == 1 || quantity =~ /^1(\.0+)?$/) ? box_name : box_name.pluralize)
  end

  def string_sort_code
    result = box.name
    result += '+L' unless likes.blank?
    result += '+D' unless dislikes.blank?
    result.upcase
  end

  def schedule_empty?
    schedule.next_occurrence.blank?
  end
  
  def deactivate
    self.active = false
  end

  def pause(start_date, end_date)

    # Could not get controller response to render error, so commented out
    # for now.
    if start_date.past? || end_date.past?
      #errors.add(:base, "Dates can not be in the past")
      return false
    elsif end_date <= start_date
      #errors.add(:base, "Start date can not be past end date")
      return false
    end

    updated_schedule = schedule
    updated_schedule.exception_times.each { |time| updated_schedule.remove_exception_time(time) }
    (start_date..end_date).each   { |date| updated_schedule.add_exception_time(date.beginning_of_day) }
    self.schedule = updated_schedule
    save
  end

  protected

  # Manually create the first delivery all following deliveries should be scheduled for creation by the cron job
  def activate
    self.active = true
  end

  def record_schedule_change
    order_schedule_transactions.build(order: self, schedule: self.schedule)
  end
end

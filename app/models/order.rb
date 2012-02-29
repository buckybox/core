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

  before_save :make_active, if: :just_completed?
  before_save :record_schedule_change

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
      montly_days_hash = days_by_number.inject({}) { |hash, day| hash[day] = [1]; hash }

      recurrence_rule = Rule.monthly.day_of_week(montly_days_hash)
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
    logger.info "--- Deactivating orders with no other occurrences ---"

    active.each do |order|
      logger.info "Processing: #{order.id}"

      if order.schedule.next_occurrence.nil?
        logger.info '> Deactivating...'
        order.update_attribute(:active, false)
        logger.info '> Done.'
      end
    end
  end

  def price
    individual_price * quantity
  end

  def individual_price
    (box.price + route.fee) * (1 - customer.discount)
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

  protected

  # Manually create the first delivery all following deliveries should be scheduled for creation by the cron job
  def make_active
    self.active = true
  end

  def record_schedule_change
    order_schedule_transactions.build(order: self, schedule: self.schedule)
  end
end

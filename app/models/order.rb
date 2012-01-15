class Order < ActiveRecord::Base
  include IceCube

  belongs_to :account
  belongs_to :box

  has_one :distributor, :through => :box
  has_one :customer, :through => :account
  has_one :route, :through => :customer

  has_many :deliveries, :dependent => :destroy
  has_many :routes, :through => :deliveries
  has_many :order_schedule_transactions

  acts_as_taggable
  serialize :schedule, Hash

  attr_accessible :box, :box_id, :account, :account_id, :quantity, :likes, :dislikes, :completed, :frequency

  FREQUENCIES = %w(single weekly fortnightly)
  FREQUENCY_IN_WEEKS = [nil, 1, 2] # to be transposed to the FREQUENCIES array
  FREQUENCY_HASH = Hash[[FREQUENCIES, FREQUENCY_IN_WEEKS].transpose]

  validates_presence_of :box, :quantity, :frequency
  validates_presence_of :account, :on => :update
  validates_numericality_of :quantity, :greater_than => 0
  validates_inclusion_of :frequency, :in => FREQUENCIES, :message => "%{value} is not a valid frequency"
  validate :box_distributor_equals_customer_distributor

  before_save :create_schedule, :if => 'schedule.first.nil?'
  before_save :make_active_and_create_first_delivery, :if => :just_completed?
  before_save :record_schedule_change

  scope :completed, where(:completed => true)
  scope :active,    where(:active => true)

  def price
    box.price #will likely need to copy this to the order model at some stage
  end

  def customer= cust
    self.account = cust.account
  end

  def self.deactivate_finished
    active.each do |order|
      if order.schedule.next_occurrence.nil?
        order.update_attribute(:active, false)
      end
    end
  end

  def self.create_next_delivery
    active.each { |d| d.create_next_delivery }
  end

  def create_next_delivery
    if completed? && active?
      current_route = customer.route
      date = schedule.next_occurrence
      delivery = deliveries.find_or_create_by_date_and_route_id(date, current_route.id) if date && current_route
    end
  end

  # Maintenance method. Should only need if cron isn't running or missed some dates
  def self.create_old_deliveries
    all.each { |o| o.create_old_deliveries }
  end

  # Maintenance method. Should only need if cron isn't running or missed some dates
  def create_old_deliveries
    schedule.occurrences(Time.now).each do |occurrence|
      current_route = customer.route
      date = occurrence.to_date
      result = deliveries.find_or_create_by_date_and_route_id(date, current_route.id) if date && current_route
    end
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
    time = schedule.recurrence_times.select{|t|t.to_date <=> delivery.date}.first
    s.remove_recurrence_time(time)
    self.schedule = s
  end

  def string_pluralize
    "#{quantity || 0} " + ((quantity == 1 || quantity =~ /^1(\.0+)?$/) ? box.name : box.name.pluralize)
  end

  def delivery_for_date(date)
    deliveries.where(:date => date)
    (deliveries.empty? ? nil : deliveries.first)
  end

  def check_status_by_date(date)
    if schedule.occurs_on?(date.to_time) # is it even suposed to happen on this date?
      (date.future? ? 'pending' : delivery_for_date(date).status)
    end
  end

  protected

  def create_schedule
    weeks_between_deliveries = FREQUENCY_HASH[frequency]
    current_route = customer.route

    if current_route
      next_run = current_route.next_run
      new_schedule = Schedule.new(next_run)

      if weeks_between_deliveries
        recurrence_rule = Rule.weekly(weeks_between_deliveries)
        new_schedule.add_recurrence_rule(recurrence_rule)
      else
        new_schedule.add_recurrence_date(next_run)
      end

      self.schedule = new_schedule
    end
  end

  # Manually create the first delivery all following deliveries should be scheduled for creation by the cron job
  def make_active_and_create_first_delivery
    self.active = true
    create_next_delivery
  end

  def record_schedule_change
    order_schedule_transactions.build(order: self, schedule: self.schedule)
  end

  #TODO: Fix hacks as a result of customer accounts model rejig
  def box_distributor_equals_customer_distributor
    if customer && customer.distributor_id != box.distributor_id
      errors.add(:box, 'distributor does not match customer distributor')
    end
  end
end

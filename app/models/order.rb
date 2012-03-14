class Order < ActiveRecord::Base
  include Bucky

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

    Bucky.create_schedule(start_time, frequency, days_by_number)
  end

  def self.deactivate_finished
    logger.info "--- Deactivating orders with no other occurrences ---"

    active.each do |order|
      order.use_local_time_zone do

        logger.info "Processing: #{order.id}"

        if order.schedule.next_occurrence.nil?
          logger.info '> Deactivating...'
          order.update_attribute(:active, false)
          logger.info '> Done.'
        end
      end
    end
  end

  def change_to_local_time_zone
    distributor.change_to_local_time_zone
  end

  def use_local_time_zone
    distributor.use_local_time_zone do
      yield
    end
  end

  def local_time_zone
    distributor.local_time_zone
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
    schedule.occurrences_between(Time.current, end_date).each do |occurence|
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
  
  def self.fix_schedule_time_zones
    Order.all.select do |order|
      new_schedule = order.schedule
      new_schedule.start_time = new_schedule.start_time.in_time_zone(order.distributor.get_time_zone)
      order.schedule = new_schedule
      [order.save, order]
    end
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

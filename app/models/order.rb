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

  FREQUENCIES = %w(single weekly fortnightly)
  FREQUENCY_IN_WEEKS = [nil, 1, 2] # to be transposed to the FREQUENCIES array
  FREQUENCY_HASH = Hash[[FREQUENCIES, FREQUENCY_IN_WEEKS].transpose]

  validates_presence_of :box, :quantity, :frequency, :account, :schedule
  validates_numericality_of :quantity, greater_than: 0
  validates_inclusion_of :frequency, in: FREQUENCIES, message: "%{value} is not a valid frequency"
  validate :box_distributor_equals_customer_distributor

  before_save :make_active, if: :just_completed?
  before_save :record_schedule_change

  default_scope order('created_at DESC')

  scope :completed, where(completed: true)
  scope :active,    where(active: true)
  scope :inactive,  where(active: false)

  def price
    individual_price * quantity
  end

  def individual_price
    (box.price + route.fee) * (1 - customer.discount)
  end

  def customer= cust
    self.account = cust.account
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

  #TODO: Fix hacks as a result of customer accounts model rejig
  def box_distributor_equals_customer_distributor
    if customer && customer.distributor_id != box.distributor_id
      errors.add(:box, 'distributor does not match customer distributor')
    end
  end
end

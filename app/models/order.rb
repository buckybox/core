class Order < ActiveRecord::Base
  include Bucky

  belongs_to :account
  belongs_to :box

  has_one :customer,    through: :account
  has_one :distributor, through: :account
  has_one :address,     through: :account
  has_one :route,       through: :account

  has_many :packages
  has_many :deliveries
  has_many :order_schedule_transactions, autosave: true

  has_many :order_extras, autosave: true
  has_many :extras, through: :order_extras

  scope :completed, where(completed: true)
  scope :active, where(active: true)

  schedule_for :schedule

  acts_as_taggable

  attr_accessible :box, :box_id, :account, :account_id, :quantity, :likes, :dislikes, :completed, :frequency, :schedule, :order_extras, :extras_one_off

  FREQUENCIES = %w(single weekly fortnightly monthly)

  validates_presence_of :account_id, :box_id, :quantity, :frequency
  validates_length_of :schedule, minimum: 1, too_short: 'need more data to create the schedule' # we may want a custom validator sometime
  validates_numericality_of :quantity, greater_than: 0
  validates_inclusion_of :frequency, in: FREQUENCIES, message: "%{value} is not a valid frequency"
  validate :extras_within_box_limit
  validate :schedule_includes_route

  before_validation :activate, if: :just_completed?
  before_validation :record_schedule_change, if: :schedule_changed?

  default_scope order('created_at DESC')

  scope :completed, where(completed: true)
  scope :active,    where(active: true)
  scope :inactive,  where(active: false)

  delegate :local_time_zone, to: :distributor, allow_nil: true

  default_value_for :extras_one_off, false

  def create_schedule(start_time, frequency, days_by_number = nil)
    if frequency != 'single' && days_by_number.nil?
      raise(ArgumentError, "Unless it is a single order the schedule needs to specify days.")
    end

    create_schedule_for(:schedule, start_time, frequency, days_by_number)
  end

  def self.deactivate_finished
    active.each do |order|
      order.use_local_time_zone do
        if order.schedule.next_occurrence.nil?
          order.update_attribute(:active, false)
          CronLog.log("Deactivated order #{order.id}")
        end
      end
    end
  end

  def self.for_route_read_only(route)
    # Using a join makes the returned models read-only, this is a work around
    order_ids = Order.where(customers: {route_id: route.id}).joins(:customer).collect(&:id)
    Order.where(["id in (?)", order_ids])
  end

  def create_schedule(start_time, frequency, days_by_number = nil)
    if start_time.is_a?(String)
      start_time = Date.parse(start_time).to_time
    elsif start_time.is_a?(Date)
      start_time = start_time.to_time
    end

    if frequency == 'single'
      create_schedule_for(:schedule, start_time, frequency)
    elsif !days_by_number.nil?
      days_by_number = days_by_number.values.map(&:to_i) if days_by_number.is_a?(Hash)

      create_schedule_for(:schedule, start_time, frequency, days_by_number)
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

  def price
    result = individual_price * quantity
    result += extras_price if extras.present?
    result
  end

  def individual_price
    Package.calculated_price(box, route, customer)
  end

  def extras_price
    Package.calculated_extras_price(order_extras, customer)
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

  def remove_day(day)
    remove_recurrence_rule_day(day)
    remove_recurrence_times_on_day(day)
  end

  def deactivate_for_day!(day)
    remove_day(day)
    deactivate if schedule_empty?
    save!
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

  def order_extras=(collection)
    raise "I wasn't expecting you to set these directly" unless collection.is_a?(Hash) || collection.is_a?(Array)
    
    order_extras.destroy_all

    collection.to_a.compact.each do |id, params|
      count = params[:count]
      next if count.to_i.zero?
      order_extra = order_extras.build(extra_id: id)
      order_extra.count = count
    end
  end

  def extras_description(show_frequency=false)
    extras_string = Package.extras_description(order_extras)
    if schedule.frequency.single? || !show_frequency
      extras_string
    else
      extras_string + (extras_one_off? ? ", include in the next delivery only" : ", include with every delivery") if order_extras.count > 0
    end
  end

  def pack_and_update_extras
    packed_extras = order_extras.collect(&:to_hash)
    clear_extras if extras_one_off # Now that the extras are in a package, we don't need them on the order anymore, unless it reoccurs

    packed_extras
  end

  def clear_extras
    self.extras = []
  end

  def contents_description
    Package.contents_description(box, quantity, order_extras)
  end

  def extras_summary
    Package.extras_summary(order_extras)
  end

  # Manually create the first delivery all following deliveries should be scheduled for creation by the cron job
  def activate
    self.active = true
  end

  def include_extras
    new_record? || !order_extras.count.zero?
  end
  
  def extras_count
    order_extras.collect(&:count).sum
  end

  protected

  def record_schedule_change
    order_schedule_transactions.new(order: self, schedule: self.schedule)
  end

  def schedule_includes_route
    unless account.route.schedule.include?(schedule)
      errors.add(:schedule, "Route #{account.route.name}'s schedule '#{account.route.schedule.start_time} #{account.route.schedule} doesn't include this order's schedule of '#{schedule.start_time} #{schedule}'")
    end
    # account.route and not route because sometimes route isn't around at creation time but account.route has it in memory
  end

  def extras_within_box_limit
    if box.present? && !box.extras_unlimited? && extras_count > box.extras_limit
      errors.add(:base, "There is more than #{box.extras_limit} extras for this box") 
    end
  end

  private

  def remove_recurrence_rule_day(day)
    s = schedule
    s.remove_recurrence_rule_day(day)
    self.schedule = s
  end

  def remove_recurrence_times_on_day(day)
    s = schedule
    s.remove_recurrence_times_on_day(day)
    self.schedule = s
  end
end

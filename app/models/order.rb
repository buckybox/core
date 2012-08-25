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
  has_many :exclusions,                  autosave: true
  has_many :substitutions,               autosave: true
  has_many :order_schedule_transactions, autosave: true
  has_many :order_extras,                autosave: true

  has_many :extras, through: :order_extras

  scope :completed, where(completed: true)
  scope :active, where(active: true)

  schedule_for :schedule

  acts_as_taggable

  attr_accessible :box, :box_id, :account, :account_id, :quantity, :completed, :frequency, :schedule, 
    :order_extras, :extras_one_off

  FREQUENCIES = %w(single weekly fortnightly monthly)

  validates_presence_of :account_id, :box_id, :quantity, :frequency
  validates_numericality_of :quantity, greater_than: 0
  validates_inclusion_of :frequency, in: FREQUENCIES, message: "%{value} is not a valid frequency"
  validate :schedule_includes_route
  validate :extras_within_box_limit

  before_validation :activate, if: :just_completed?
  before_validation :record_schedule_change, if: :schedule_changed?

  default_scope order('created_at DESC')

  scope :completed, where(completed: true)
  scope :active,    where(active: true)
  scope :inactive,  where(active: false)

  delegate :local_time_zone, to: :distributor, allow_nil: true

  default_value_for :extras_one_off, false
  default_value_for :quantity, 1

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
    # Getting the data needed via a join
    order_ids = Order.where(customers: { route_id: route.id }).joins(:customer).map(&:id)
    # The join causes the returned models to be read-only. Thus, must to another search to get updateable models returned.
    Order.where(id: order_ids)
  end

  def create_schedule(start_time, frequency, days_by_number = nil)
    if start_time.is_a?(String)
      start_time = Time.zone.parse(start_time)
    elsif start_time.is_a?(Date)
      start_time = start_time.to_time_in_current_zone
    end

    if frequency == 'single'
      create_schedule_for(:schedule, start_time, frequency)
    elsif !days_by_number.nil?
      days_by_number = days_by_number.values.map(&:to_i) if days_by_number.is_a?(Hash)
      create_schedule_for(:schedule, start_time, frequency, days_by_number)
    end
  end

  def update_exclusions(line_item_ids)
    return if line_item_ids.nil? || !box.dislikes? || !box.likes?

    line_item_ids = line_item_ids.map(&:to_i)
    exclusion_line_item_ids = exclusions.map { |x| x.line_item_id }

    to_delete = exclusion_line_item_ids - line_item_ids
    to_create = line_item_ids - exclusion_line_item_ids

    exclusions.each { |x| x.mark_for_destruction if to_delete.include?(x.line_item_id) }
    to_create.each { |liid| exclusions.find_or_initialize_by_line_item_id(liid) }
  end

  def update_substitutions(line_item_ids)
    return if line_item_ids.nil? || !box.dislikes? || !box.likes?

    line_item_ids = line_item_ids.map(&:to_i)
    substitution_line_item_ids = substitutions.map { |x| x.line_item_id }

    to_delete = substitution_line_item_ids - line_item_ids
    to_create = line_item_ids - substitution_line_item_ids

    substitutions.each { |x| x.mark_for_destruction if to_delete.include?(x.line_item_id) }
    to_create.each { |liid| substitutions.find_or_initialize_by_line_item_id(liid) }
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
    s.add_recurrence_time(delivery.date.to_time_in_current_zone)
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

  def remove_day(day)
    remove_recurrence_rule_day(day)
    remove_recurrence_times_on_day(day)
  end

  def deactivate_for_day!(day)
    remove_day(day) unless schedule_empty?
    deactivate if schedule_empty?
    save!
  end

  def schedule_empty?
    schedule.nil? || schedule.next_occurrence.blank? || schedule.empty?
  end

  def string_pluralize
    box_name = box.name
    "#{quantity || 0} " + ((quantity == 1 || quantity =~ /^1(\.0+)?$/) ? box_name : box_name.pluralize)
  end

  def string_sort_code
    result = box.name
    result += '+L' unless exclusions.empty?
    result += '+D' unless substitutions.empty?

    return result.upcase
  end

  def deactivate
    self.active = false
  end

  def order_extras=(collection)
    raise "I wasn't expecting you to set these directly" unless collection.is_a?(Hash) || collection.is_a?(Array)

    order_extras.destroy_all

    collection.to_a.compact.each do |id, params|
      count = params[:count]
      next if count.to_i.zero?
      order_extra = order_extras.build(extra_id: id)
      order_extra.count = count.to_i
    end
  end

  def pause!(start_date, end_date)
    return false if start_date.past? || end_date.past? || (end_date < start_date)

    new_schedule = self.schedule
    new_schedule.pause(start_date, end_date)
    self.schedule = new_schedule
    self.save
  end

  def remove_pause!
    new_schedule = self.schedule
    new_schedule.remove_pause
    self.schedule = new_schedule
    self.save
  end

  def pause_date
    schedule.pause_date
  end

  def resume_date
    schedule.resume_date
  end

  def possible_pause_dates(look_ahead = 8.weeks)
    start_time          = distributor.window_end_at.to_time_in_current_zone + 1.day
    end_time            = start_time + look_ahead
    existing_pause_date = pause_date

    select_array = schedule.occurrences(end_time, start_time).map { |s| [s.to_date.to_s(:pause), s.to_date] }

    if existing_pause_date && !select_array.index(existing_pause_date)
      select_array << [existing_pause_date.to_s(:pause), existing_pause_date]
      select_array.sort! { |a,b| a.second <=> b.second }
    end

    return select_array
  end

  def possible_resume_dates(look_ahead = 12.weeks)
    if pause_date
      start_time           = pause_date.to_time_in_current_zone
      end_time             = start_time + look_ahead
      existing_resume_date = pause_date

      no_pause_schedule = self.schedule
      no_pause_schedule = no_pause_schedule.remove_pause
      select_array      = no_pause_schedule.occurrences(end_time, start_time).map { |s| [s.to_date.to_s(:pause), s.to_date] }

      if existing_resume_date && !select_array.index(existing_resume_date)
        select_array << [existing_resume_date.to_s(:pause), existing_resume_date]
        select_array.sort! { |a,b| a.second <=> b.second }
      end
    end

    return select_array || []
  end

  def extras_description(show_frequency = false)
    extras_string = Package.extras_description(order_extras)

    if schedule.frequency.single? || !show_frequency
      extras_string
    else
      extras_string + (extras_one_off? ? ", include in the next delivery only" : ", include with every delivery") if order_extras.count > 0
    end
  end

  def customisation_description
    exclusions_string = exclusions.includes(:line_item).map(&:name).join(', ')
    substitution_string = substitutions.includes(:line_item).map(&:name).join(', ')

    unless exclusions_string.blank?
      result_string = "Exclude #{exclusions_string}"
      result_string += "/ Substitute #{substitution_string}" unless substitution_string.blank?
    end

    return result_string
  end

  def pack_and_update_extras
    packed_extras = order_extras.collect(&:to_hash)
    clear_extras if extras_one_off # Now that the extras are in a package, we don't need them on the order anymore, unless it reoccurs

    packed_extras
  end

  def clear_extras
    self.extras = []
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

  def import_extras(b_extras)
    self.order_extras = b_extras.inject({}) do |params, extra|
      found_extra = distributor.find_extra_from_import(extra, box)
      raise "Didn't find an extra to import" if found_extra.blank?
      params.merge(found_extra.id.to_s => {count: extra.count})
    end
  end

  def dso(wday)
    dso = DeliverySequenceOrder.where(address_hash: address.address_hash, day: wday, route_id: route.id).first
    dso && dso.position || -1
  end

  def route_id
    account.customer.route_id
  end

  protected

  def record_schedule_change
    order_schedule_transactions.new(order: self, schedule: self.schedule)
  end

  def schedule_includes_route
    unless account.route.schedule.include?(schedule)
      errors.add(:schedule, "Route #{account.route.name}'s schedule '#{account.route.schedule} doesn't include this order's schedule of '#{schedule}'")
    end
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

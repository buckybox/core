class Order < ActiveRecord::Base
  include Bucky

  belongs_to :account
  belongs_to :box

  has_one :customer,         through: :account
  has_one :distributor,      through: :account
  has_one :address,          through: :account
  has_one :delivery_service, through: :account

  has_many :packages
  has_many :deliveries
  has_many :exclusions,    autosave: true, after_add: Proc.new {|o, s| s.order = o}
  has_many :substitutions, autosave: true, after_add: Proc.new {|o, s| s.order = o}
  has_many :order_extras,  autosave: true

  has_many :excluded_line_items, through: :exclusions, source: :line_item
  has_many :substituted_line_items, through: :substitutions, source: :line_item


  has_many :extras, through: :order_extras

  belongs_to :extras_packing_list, class_name: PackingList

  has_one :schedule_rule, as: :scheduleable, inverse_of: :scheduleable, autosave: true, dependent: :destroy

  scope :completed, where(completed: true)
  scope :active, where(active: true)
  scope :inactive, where(active: false)

  after_save :check_halted_status
  after_save :update_next_occurrence #This is an after call because it works at the database level and requires the information to be commited
  after_destroy :update_next_occurrence
  after_create :remind_customer_if_halted

  acts_as_taggable

  attr_accessible :box, :box_id, :account, :account_id, :quantity, :completed, 
    :order_extras, :extras_one_off, :schedule_rule_attributes, :schedule_rule,
    :excluded_line_item_ids, :substituted_line_item_ids

  accepts_nested_attributes_for :schedule_rule

  IS_ONE_OFF  = false
  QUANTITY    = 1
  FORCAST_RANGE_BACK = 9.weeks
  FORCAST_RANGE_FORWARD = 6.weeks

  validates_presence_of :account_id, :box_id, :quantity, unless: :effectively_deactivated?
  validates_numericality_of :quantity, greater_than: 0, unless: :effectively_deactivated?
  validate :delivery_service_includes_schedule_rule, unless: :effectively_deactivated?
  validate :extras_within_box_limit, unless: :effectively_deactivated?
  validate :likes_dislikes_within_limits, unless: :effectively_deactivated?

  before_validation :activate, if: :just_completed?

  default_scope order('created_at DESC')

  delegate :local_time_zone, to: :distributor, allow_nil: true
  delegate :start, :recurs?, :pause!, :remove_pause!, :paused?, :pause_date, :resume_date, :next_occurrence, :next_occurrences, :remove_day, :occurrences_between, to: :schedule_rule
  delegate :halted?, to: :customer

  default_value_for :extras_one_off, IS_ONE_OFF
  default_value_for :quantity, QUANTITY

  after_initialize :set_default_schedule_rule

  def set_default_schedule_rule
    self.schedule_rule ||= ScheduleRule.one_off(Date.current) if new_record?
  end

  # TODO: move to decorator
  def self.dates_grid
    days = []
    4.times do |week| # 4 first weeks of the month
      days << ScheduleRule::DAYS.map do |day|
        [day.to_s.titleize, ScheduleRule::DAYS.index(day) + ScheduleRule::DAYS.size * week]
      end
    end
    days
  end

  # TODO: move to decorator
  def self.start_dates(delivery_service, time_from_now = nil)
    time_from_now ||= 12.weeks.from_now
    from_time = delivery_service.distributor.window_end_at + 1.day #next_occurrence includes the start date, so choose the next day
    next_occurrences = delivery_service.occurrences_between(from_time, time_from_now)
    next_occurrences.map do |time|
      [
        time.to_s(:delivery_service_dates),
        time.to_date,
        { 'data-weekday' => time.strftime('%a').downcase }
      ]
    end
  end

  def self.deactivate_finished
    active.each do |order|
      order.use_local_time_zone do
        if order.should_deactivate?
          order.update_attribute(:active, false)
          CronLog.log("Deactivated order #{order.id}")
        end
      end
    end
  end

  def self.for_delivery_service_read_only(delivery_service)
    # Getting the data needed via a join
    order_ids = Order.where(customers: { delivery_service_id: delivery_service.id }).joins(:customer).map(&:id)
    # The join causes the returned models to be read-only. Thus, must to another search to get updateable models returned.
    Order.where(id: order_ids)
  end

  def self.short_code(box_name, has_exclusions, has_substitutions)
    result = box_name || ''
    result += '+L' if has_exclusions
    result += '+D' if has_substitutions
    result.upcase
  end

  def self.extras_description(order_extras)
    order_extras = order_extras.map(&:to_hash) unless order_extras.is_a? Hash
    order_extras.map{ |e| "#{e[:count]}x #{e[:name]} #{e[:unit]}" }.join(', ')
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
    OrderPrice.without_delivery_fee(individual_price, quantity, extras_price, extras.present?)
  end

  def consumer_delivery_fee
    distributor.consumer_delivery_fee
  end

  def total_price
    OrderPrice.with_delivery_fee(price, consumer_delivery_fee)
  end

  def individual_price
    OrderPrice.individual(box, delivery_service, customer)
  end

  def extras_price
    OrderPrice.extras_price(order_extras, customer)
  end

  def customer=(cust)
    self.account = cust.account
  end

  def just_completed?
    completed_changed? && completed?
  end

  def future_deliveries(end_date)
    results = []

    schedule_rule.occurrences_between(Time.current, end_date).each do |occurence|
      results << { date: occurence.to_date, price: self.price, description: "Delivery for order ##{id}"}
    end

    return results
  end

  def deactivate_for_days!(days)
    if deactived_after_removed_days?(days)
      deactivate
    else
      days.each do |day|
        remove_day(day)
      end
    end
    save!
  end

  def deactived_after_removed_days?(days)
    (schedule_rule.days - days.collect{|i| ScheduleRule::DAYS[i]}).blank?
  end

  def schedule_empty?
    schedule_rule.blank? || schedule_rule.next_occurrence.blank? || !schedule_rule.has_at_least_one_day?
  end

  def box_name
    box.name
  end

  def delivery_service_name
    delivery_service.name
  end

  def has_exclusions?
    !exclusions.empty?
  end

  def has_substitutions?
    !substitutions.empty?
  end

  def string_pluralize
    "#{quantity || 0} " + ((quantity == 1 || quantity =~ /^1(\.0+)?$/) ? box_name : box_name.pluralize)
  end

  def string_sort_code
    result = box_name
    result += '+L' if has_exclusions?
    result += '+D' if has_substitutions?

    return result.upcase
  end

  def deactivate
    self.active = false
  end

  def inactive?
    !active?
  end

  def order_extras=(collection)
    raise "I wasn't expecting you to set these directly" unless collection.is_a?(Hash) || collection.is_a?(Array)

    original_order_extras.destroy_all
    self.extras_packing_list = nil

    collection.to_a.compact.each do |id, params|
      count = params[:count]
      next if count.to_i.zero?
      order_extra = order_extras.build(extra_id: id)
      order_extra.count = count.to_i
    end
  end

  def predicted_order_extras(date = nil)
    date = Date.current unless date.is_a?(Date)
    if date == Date.current || !extras_one_off?
      order_extras
    else
      if extras_packing_list.present? || next_occurrence_before(distributor.beginning_of_green_zone, date)
        order_extras.none
      else
        order_extras
      end
    end
  end

  def next_occurrence_before(date, test_date)
    next_date = next_occurrence(date)
    next_date.present? && next_date < test_date
  end

  def has_yellow_deliveries?
    !deliveries.pending.count.zero?
  end

  def possible_pause_dates(look_ahead = 8.weeks)
    start_time          = [distributor.window_end_at.to_time_in_current_zone.to_date + 1.day, start].max
    end_time            = start_time + look_ahead
    existing_pause_date = pause_date

    select_array = self.schedule_rule.occurrences_between(start_time, end_time, {ignore_pauses: true, ignore_halts: true}).map { |s| [s.to_date.to_s(:pause), s.to_date] }

    if existing_pause_date && !select_array.index([existing_pause_date.to_s(:pause), existing_pause_date])
      select_array << [existing_pause_date.to_s(:pause), existing_pause_date]
      select_array.sort! { |a,b| a.second <=> b.second }
    end

    return select_array
  end

  def possible_resume_dates(look_ahead = 12.weeks)
    if pause_date
      start_time           = [(pause_date + 1.day).to_time_in_current_zone, distributor.window_end_at.to_time_in_current_zone + 1.day].max
      end_time             = start_time + look_ahead
      existing_resume_date = resume_date

      select_array      = self.schedule_rule.occurrences_between(start_time, end_time, {ignore_pauses: true, ignore_halts: true}).map { |s| [s.to_date.to_s(:pause), s.to_date] }

      if existing_resume_date && !select_array.index([existing_resume_date.to_s(:pause), existing_resume_date])
        select_array << [existing_resume_date.to_s(:pause), existing_resume_date]
        select_array.sort! { |a,b| a.second <=> b.second }
      end
    end

    return select_array || []
  end

  def extra_string(extra)
    "#{extra.name} (#{extra.unit})"
  end

  def extra_count(extra)
    order_extras.where(extra_id: extra.id).sum(&:count)
  end

  def extras_description(show_frequency = false)
    extras_string = Order.extras_description(order_extras)

    if schedule_rule.frequency.single? || !show_frequency
      extras_string
    else
      extras_string + (extras_one_off? ? ", include in the next delivery only" : ", include with every delivery") if order_extras.count > 0
    end
  end

  def exclusions_string
    exclusions.includes(:line_item).map(&:name).join(', ')
  end

  def substitutions_string
    substitutions.includes(:line_item).map(&:name).join(', ')
  end

  def customisation_description
    unless exclusions_string.blank?
      result_string = "Exclude #{exclusions_string}"
      result_string += "/ Substitute #{substitutions_string}" unless substitutions_string.blank?
    end

    return result_string
  end

  alias_method :original_order_extras, :order_extras
  def order_extras
    if extras_delivered? && extras_one_off?
      original_order_extras.none
    else
      original_order_extras
    end
  end

  alias_method :original_extras, :extras
  def extras
    if extras_delivered? && extras_one_off?
      original_extras.none
    else
      original_extras
    end
  end

  def pack_and_update_extras(package)
    return [] if extras_one_off? && extras_processed?

    packed_extras = original_order_extras.collect(&:to_hash)
    package.set_one_off_extra_order(self) if extras_one_off?

    return packed_extras
  end

  def extras_processed?
    extras_packing_list.present?
  end

  def extras_delivered?
    extras_packing_list.present? && extras_packing_list.packages.where(order_id:self.id).first.deliveries.any?(&:delivered?)
  end

  def set_extras_package!(package)
    self.extras_packing_list = package.packing_list
    save!
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
    dso_position = DeliverySequenceOrder.position_for(address.address_hash, wday, delivery_service.id)
    dso_position || -1
  end

  def delivery_service_id
    account.customer.delivery_service_id
  end

  def self.order_count(distributor, date, delivery_service_id=nil)
    distributor.use_local_time_zone do
      Bucky::Sql.order_count(distributor, date, delivery_service_id)
    end
  end

  def schedule_changed(schedule_rule)
    update_next_occurrence
  end

  def limits_data
    distributor.boxes.all.inject({}) do |hash, element|
      hash.merge(element.id => element.limits_data)
    end.to_json
  end

  def should_deactivate?
    schedule_rule.no_occurrences? && !paused? && !halted?
  end

  def pending_package_creation?
    return false if inactive?

    use_local_time_zone do
      return next_occurrence(distributor.window_end_at + 1.day).present?
    end
  end

  def completed!
    self.completed = true
  end

  # If we saved the current state of this order, would it be rendered deactivated?
  def effectively_deactivated?
    inactive? || (!new_record? && next_occurrence.nil?)
  end

  protected

  def update_next_occurrence
    customer.update_next_occurrence.save!
  end

  def delivery_service_includes_schedule_rule
    if !account.delivery_service.includes?(schedule_rule, {ignore_start: true})
      errors.add(:schedule_rule, "DeliveryService #{account.delivery_service.name}'s schedule '#{account.delivery_service.schedule_rule.inspect} doesn't include this order's schedule of '#{schedule_rule.inspect}'")
    end
  end

  def extras_within_box_limit
    if box.present? && new_record? && !box.extras_unlimited? && extras_count > box.extras_limit
      errors.add(:base, "There is more than #{box.extras_limit} extras for this box")
    end
  end

  def likes_dislikes_within_limits
    return unless new_record? && box.present?

    if !box.exclusions_limit.zero? && exclusions.size > box.exclusions_limit
      errors.add(:exclusions, " is limited to #{box.exclusions_limit}")
    end

    if !box.substitutions_limit.zero? && substitutions.size > box.substitutions_limit
      errors.add(:substitutions, " is limited to #{box.substitutions_limit}")
    end
  end

  def check_halted_status
    if halted?
      schedule_rule.halt!
    else
      schedule_rule.unhalt!
    end
  end

  def remind_customer_if_halted
    customer.remind_customer_is_halted if halted?
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

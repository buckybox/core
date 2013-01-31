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
  has_many :order_extras,                autosave: true

  has_many :excluded_line_items, through: :exclusions, source: :line_item
  has_many :substituted_line_item, through: :substitutions, source: :line_item


  has_many :extras, through: :order_extras

  has_one :schedule_rule, as: :scheduleable, inverse_of: :scheduleable, autosave: true, dependent: :destroy

  scope :completed, where(completed: true)
  scope :active, where(active: true)

  after_save :update_next_occurrence #This is an after call because it works at the database level and requires the information to be commited
  after_destroy :update_next_occurrence

  acts_as_taggable

  attr_accessible :box, :box_id, :account, :account_id, :quantity, :completed, 
    :order_extras, :extras_one_off, :schedule_rule_attributes, :schedule_rule

  accepts_nested_attributes_for :schedule_rule

  IS_ONE_OFF  = false
  QUANTITY    = 1
  FORCAST_RANGE_BACK = 9.weeks
  FORCAST_RANGE_FORWARD = 6.weeks

  validates_presence_of :account_id, :box_id, :quantity
  validates_numericality_of :quantity, greater_than: 0
  validate :route_includes_schedule_rule
  validate :extras_within_box_limit
  validate :likes_dislikes_within_limits

  before_validation :activate, if: :just_completed?

  default_scope order('created_at DESC')

  scope :completed, where(completed: true)
  scope :active,    where(active: true)
  scope :inactive,  where(active: false)

  delegate :local_time_zone, to: :distributor, allow_nil: true
  delegate :start, :recurs?, :pause!, :remove_pause!, :pause_date, :resume_date, :next_occurrence, :next_occurrences, :remove_day, :occurrences_between, to: :schedule_rule

  default_value_for :extras_one_off, IS_ONE_OFF
  default_value_for :quantity, QUANTITY
  
  after_initialize :set_default_schedule_rule

  def set_default_schedule_rule
    self.schedule_rule ||= ScheduleRule.one_off(Date.current) if new_record?
  end

  def self.deactivate_finished
    active.each do |order|
      order.use_local_time_zone do
        if order.schedule_rule.next_occurrence.nil?
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

  def dislikes_input=(params)
    self.excluded_line_item_ids = params
  end

  def likes_input=(params)
    self.substituted_line_item_ids = params
  end

  def update_exclusions(exclusions)
    self.dislikes_input = exclusions.collect(&:to_i)
  end

  def update_substitutions(substitutions)
    self.likes_input = substitutions.collect(&:to_i)
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
    return result
  end

  def individual_price
    Package.calculated_individual_price(box, route, customer)
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

  def future_deliveries(end_date)
    results = []

    schedule_rule.occurrences_between(Time.current, end_date).each do |occurence|
      results << { date: occurence.to_date, price: self.price, description: "Delivery for order ##{id}"}
    end

    return results
  end

  def deactivate_for_day!(day)
    remove_day(day) unless schedule_empty?
    deactivate if schedule_empty?
    save!
  end

  def schedule_empty?
    schedule_rule.blank? || schedule_rule.next_occurrence.blank?
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

  def predicted_order_extras(date = nil)
    date = Date.current unless date.is_a?(Date)
    if date == Date.current || !extras_one_off?
      order_extras
    else
      if next_occurrence < date
        order_extras.none
      else
        order_extras
      end
    end
  end

  def possible_pause_dates(look_ahead = 8.weeks)
    start_time          = [distributor.window_end_at.to_time_in_current_zone.to_date + 1.day, start].compact.max
    end_time            = start_time + look_ahead
    existing_pause_date = pause_date

    select_array = self.schedule_rule.occurrences_between(start_time, end_time, {ignore_pauses: true}).map { |s| [s.to_date.to_s(:pause), s.to_date] }

    if existing_pause_date && !select_array.index([existing_pause_date.to_s(:pause), existing_pause_date])
      select_array << [existing_pause_date.to_s(:pause), existing_pause_date]
      select_array.sort! { |a,b| a.second <=> b.second }
    end

    return select_array
  end

  def possible_resume_dates(look_ahead = 12.weeks)
    if pause_date
      start_time           = (pause_date + 1.day).to_time_in_current_zone
      end_time             = start_time + look_ahead
      existing_resume_date = resume_date

      select_array      = self.schedule_rule.occurrences_between(start_time, end_time, {ignore_pauses: true}).map { |s| [s.to_date.to_s(:pause), s.to_date] }

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
    order_extra = order_extras.where(extra_id: extra.id)
    order_extra.count if order_extra
  end

  def extras_description(show_frequency = false)
    extras_string = Package.extras_description(order_extras)

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

  def pack_and_update_extras
    packed_extras = order_extras.collect(&:to_hash)
    clear_extras if extras_one_off # Now that the extras are in a package, we don't need them on the order anymore, unless it recurs

    return packed_extras
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
    dso_position = DeliverySequenceOrder.position_for(address.address_hash, wday, route.id)
    dso_position || -1
  end

  def route_id
    account.customer.route_id
  end

  def self.order_count(distributor, date, route_id=nil)
    distributor.use_local_time_zone do
      Bucky::Sql.order_count(distributor, date, route_id)
    end
  end

  def schedule_changed(schedule_rule)
    update_next_occurrence
  end

  def limits_data
    distributor.boxes.all.inject({}){|hash, element| hash.merge(element.id => element.limits_data)}.to_json
  end

  protected

  def update_next_occurrence
    customer.update_next_occurrence.save!
  end

  def route_includes_schedule_rule
    unless account.route.includes?(schedule_rule)
      errors.add(:schedule_rule, "Route #{account.route.name}'s schedule '#{account.route.schedule_rule.inspect} doesn't include this order's schedule of '#{schedule_rule.inspect}'")
    end
  end

  def extras_within_box_limit
    if box.present? && !box.extras_unlimited? && extras_count > box.extras_limit
      errors.add(:base, "There is more than #{box.extras_limit} extras for this box")
    end
  end

  def likes_dislikes_within_limits
    return unless box.present?
    
    if !box.exclusions_limit.zero? && exclusions.size > box.exclusions_limit
      errors.add(:exclusions, " is limited to #{box.exclusions_limit}")
    end

    if !box.substitutions_limit.zero? && substitutions.size > box.substitutions_limit
      errors.add(:substitutions, " is limited to #{box.substitutions_limit}")
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

class DeliveryService < ActiveRecord::Base
  include Bucky

  belongs_to :distributor

  has_many :deliveries, dependent: :destroy
  has_many :orders, through: :deliveries
  has_many :customers
  has_one :schedule_rule, as: :scheduleable, inverse_of: :scheduleable, autosave: true

  monetize :fee_cents

  attr_accessible :distributor, :name, :fee, :instructions, :schedule_rule_attributes, :schedule_rule, :pickup_point
  accepts_nested_attributes_for :schedule_rule

  validates_presence_of :distributor_id, :name, :fee, :instructions, :schedule_rule

  default_scope { order(:name) }

  delegate :local_time_zone, to: :distributor, allow_nil: true

  delegate :includes?, :delivery_day_numbers, :next_occurrences, :runs_on, :occurrences_between, to: :schedule_rule, allow_nil: true
  delegate :sun, :mon, :tue, :wed, :thu, :fri, :sat, to: :schedule_rule, allow_nil: true

  after_initialize :set_default_schedule_rule

  before_destroy :check_no_customers_left, prepend: true

  def schedule_rule_attributes_with_recur=(attrs)
    self.schedule_rule_attributes_without_recur = attrs.merge(recur: :weekly)
  end
  alias_method :schedule_rule_attributes_without_recur=, :schedule_rule_attributes=
  alias_method :schedule_rule_attributes=, :schedule_rule_attributes_with_recur=

  def set_default_schedule_rule
    self.schedule_rule ||= ScheduleRule.weekly if new_record?
  end

  def self.default_delivery_service(distributor)
    distributor.delivery_services.first # For now the first one is the default
  end

  def self.default_delivery_service_on(distributor, time)
    distributor.delivery_services.find { |r| r.delivers_on?(time) }
  end

  def name_days_and_fee
    days = schedule_rule.days.map do |day_sym|
      I18n.t('date.abbr_day_names')[ScheduleRule::DAYS.index(day_sym)]
    end

    [
      name.titleize,
      days.join(', '),
      fee.with_currency(distributor.currency),
    ].join(" - ")
  end

  def start_dates
    end_date = Date.current + 6.months # NOTE: has to be that big for CSAs

    # NOTE: next_occurrence includes the start date, so choose the next day
    start_date = distributor.window_end_at + 1.day

    occurrences_between(start_date, end_date).map do |time|
      [
        I18n.l(time, format: "%a - %b %-d, %Y"),
        time.to_date.iso8601,
        { 'data-weekday' => time.strftime('%a').downcase }
      ]
    end
  end

  def next_run
    schedule_rule.next_occurrence
  end

  def delivers_on?(time)
    schedule_rule.occurs_on?(time.to_time)
  end

  def future_orders
    Order.for_delivery_service_read_only(self)
  end

  def schedule_changed(schedule_rule)
    day_numbers = schedule_rule.deleted_day_numbers
    return if day_numbers.blank?

    future_orders.active.each do |order|
      order.deactivate_for_days!(day_numbers)
    end
  end

  def cache_key
    [
      super,
      start_dates.hash,
    ].join("-").freeze
  end

private

  def check_no_customers_left
    if customers.present?
      errors.add(:base, "Cannot delete delivery service with customers on it")
      false
    else
      true
    end
  end
end

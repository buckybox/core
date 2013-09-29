class DeliveryService < ActiveRecord::Base
  include Bucky

  belongs_to :distributor

  has_many :deliveries, dependent: :destroy
  has_many :orders, through: :deliveries
  has_many :customers
  has_one :schedule_rule, as: :scheduleable, inverse_of: :scheduleable, autosave: true

  monetize :fee_cents

  attr_accessible :distributor, :name, :fee, :area_of_service, :estimated_delivery_time, :schedule_rule_attributes, :schedule_rule
  accepts_nested_attributes_for :schedule_rule

  validates_presence_of :distributor_id, :name, :fee, :area_of_service, :estimated_delivery_time, :schedule_rule

  default_scope order(:name)

  delegate :local_time_zone, to: :distributor, allow_nil: true
  
  delegate :includes?, :delivery_day_numbers, :next_occurrences, :runs_on, :occurrences_between, to: :schedule_rule, allow_nil: true
  delegate :sun, :mon, :tue, :wed, :thu, :fri, :sat, to: :schedule_rule, allow_nil: true

  after_initialize :set_default_schedule_rule

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
    days = schedule_rule.days.map { |d| d.to_s.titleize[0..2] }

    [
      name.titleize,
      "(#{days.join(', ')})",
      fee.with_currency(distributor.currency),
    ].join(" ")
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
    schedule_rule.deleted_day_numbers.each do |day|
      future_orders.active.each do |order|
        order.deactivate_for_day!(day)
      end
    end
  end
end

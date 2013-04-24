class WebstoreOrder < ActiveRecord::Base
  include Bucky

  belongs_to :account
  belongs_to :box
  belongs_to :order
  belongs_to :distributor
  belongs_to :route

  has_one :customer, through: :account

  serialize :exclusions, Array
  serialize :substitutions, Array
  serialize :extras, Hash

  has_one :schedule_rule, as: :scheduleable, inverse_of: :scheduleable, autosave: true, dependent: :destroy

  attr_accessible :box, :distributor, :remote_ip

  validate :extras_within_box_limit

  # Should really use state_machine here but don't have the time to risk it at the moment
  CUSTOMISE = :customise
  LOGIN     = :login
  DELIVERY  = :delivery
  COMPLETE  = :complete
  PAYMENT   = :payment
  PLACED    = :placed

  def self.box_price(box, customer = nil)
    Package.discounted(box.price, customer)
  end

  def set_default_schedule_rule
    self.schedule_rule ||= ScheduleRule.one_off(Date.current) if new_record?
  end

  def thumb_url
    box.thumb_url
  end

  def currency
    box.currency
  end

  def box_name
    box.name
  end

  def box_price(customer = nil)
    Package.discounted(box.price, customer)
  end

  def box_description
    box.description
  end

  def route_name
    route.name
  end

  def route_fee(customer = nil)
    Package.discounted(route.fee, customer)
  end

  def bucky_fee
    distributor.consumer_delivery_fee
  end

  def has_bucky_fee?
    distributor.separate_bucky_fee?
  end

  def customise_step
    self.status = CUSTOMISE
  end

  def login_step
    self.status = LOGIN
  end

  def delivery_step
    self.status = DELIVERY
  end

  def complete_step
    self.status = COMPLETE
  end

  def payment_step
    self.status = PAYMENT
  end

  def placed_step
    self.status = PLACED
  end

  def customised?
    !exclusions.empty? || !extras.empty?
  end

  def scheduled?
    !schedule_rule.nil?
  end

  def completed?
    status == PLACED
  end

  def payment_method?(test_symbol)
    payment_method.to_sym == test_symbol
  end

  def payment_method_string
    payment_method.titleize
  end

  def bank
    distributor.bank_information
  end

  def extra_objects
    @extra_objects_mem ||= Extra.find_all_by_id(extras.map(&:first))
  end

  def exclusion_objects
    @exclusion_objects_mem ||= LineItem.find_all_by_id(exclusions)
  end

  def substitution_objects
    @substitution_objects_mem ||= LineItem.find_all_by_id(substitutions)
  end

  def order_extras_price(customer = nil)
    order_extra_hash = extras.map do |id, count|
      extra_object = extra_objects.find{ |extra| extra.id == id.to_i }
      {
        name: extra_object.name,
        unit: extra_object.unit,
        price_cents: extra_object.price_cents,
        currency: extra_object.currency,
        count: count
      }
    end

    @order_extras_price_mem = Package.calculated_extras_price(order_extra_hash, customer)

    return @order_extras_price_mem
  end

  def order_price(customer = nil)
    @order_price_mem = Package.calculated_individual_price(box, route, customer)
    @order_price_mem += order_extras_price(customer) unless extras.empty?
    @order_price_mem += bucky_fee if has_bucky_fee?

    return @order_price_mem
  end

  def exclusions_string
    exclusion_objects.map(&:name).join(', ')
  end

  def substitutions_string
    substitution_objects.map(&:name).join(', ')
  end

  def customisation_description
    unless @customisation_description_mem
      unless exclusions_string.blank?
        @customisation_description_mem = "Exclude #{exclusions_string}"
        @customisation_description_mem += "/ Substitute #{substitution_string}" unless substitution_string.blank?
      end
    end

    return @customisation_description_mem
  end

  def extra_string(extra_object)
    "#{extra_object.name} (#{extra_object.unit})"
  end

  def extra_count(extra_object)
    extras[extra_object.id.to_s]
  end

  def extras_description
    unless @extras_description_mem
      @extras_description_mem = extras.map do |id, count|
        extra_object = extra_objects.find { |extra| extra.id == id.to_i }
        "#{count}x #{extra_object.name} #{extra_object.unit}"
      end.join(', ')

      if schedule_rule && !schedule_rule.frequency.single?
        @extras_description_mem += (extras_one_off? ? ', include in the next delivery only' : ', include with every delivery')
      end
    end

    return @extras_description_mem
  end

  def create_order
    if order.nil?
      extras_hash = {}
      extras.each { |id, count| extras_hash[id] = { count: count } }
      order = Order.create(
        box: box,
        completed: true,
        account: account,
        schedule_rule_attributes: schedule_rule.clone_attributes,
        order_extras: extras_hash,
        extras_one_off: extras_one_off
      )
      order.excluded_line_item_ids = exclusions
      order.substituted_line_item_ids = substitutions
      self.order = order
      order.save!
    end
  end

  # required callback from the schedule, doesn't need to do anything tho.
  def schedule_changed(schedule_rule)
  end

  def extras_count
    extra_objects.size
  end

  def extras_within_box_limit
    if box.present? && !box.extras_unlimited? && extras_count > box.extras_limit
      errors.add(:base, "The #{box.extras_limit} was exceeded for this box")
    end
  end

  def active_orders?
    customer.present? && !customer.orders.active.count.zero?
  end

  def update_customers_route(customer, route_id)
    if customer.present?
      customer.route_id = route_id
      customer.save!
    end
  end
end

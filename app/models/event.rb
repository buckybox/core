class Event < ActiveRecord::Base
  belongs_to :distributor
  attr_accessible :distributor, :event_type, :dismissed, :trigger_on, :message, :key
  validates_presence_of :distributor, :event_type, :message, :key

  before_save :set_trigger_on

  scope :active, where(dismissed: false)
  scope :current, -> { where('trigger_on <= ?', Time.current) }

  default_scope order('trigger_on DESC')

  def dismiss!
    update_attributes!(dismissed: true)
  end

  def self.new_webstore_customer(customer)
    trigger(
      customer,
      :new_webstore_customer,
      "New web store customer #{customer_badge(customer)}"
    )
  end

  def self.customer_halted(customer)
    trigger(
      customer,
      :customer_halted,
      "Deliveries halted for #{customer_badge(customer)}"
    )
  end

  def self.customer_address_changed(customer)
    trigger(
      customer,
      :customer_address_changed,
      "#{customer_badge(customer)} has updated their address"
    )
  end

  def self.new_webstore_order(order)
    message = "#{customer_badge(order.customer)} placed an order"
    payment_method = order.account.default_payment_method

    if payment_method && payment_method != PaymentOption::PAID
      payment_option = PaymentOption.new(payment_method, order.distributor)
      message << " paying by #{payment_option.option.description}"
    end

    trigger(
      order,
      :new_webstore_order,
      message
    )
  end

  def self.all_for_distributor(distributor)
    distributor.events.active.current.scoped
  end

  def set_key(resource)
    self.key = [event_type, resource.id].join
  end

private

  def self.trigger(resource, event_type, message)
    distributor = resource.distributor
    events = Event.all_for_distributor(distributor)
    new_event = Event.new(distributor: distributor, event_type: event_type, message: message)
    new_event.set_key(resource)

    events.each do |event|
      event.dismiss! if event.key == new_event.key
    end

    new_event.save!
    new_event
  end

  def self.customer_badge(customer)
    customer.decorate.badge
  end

  def set_trigger_on
    self.trigger_on ||= Time.current
  end
end

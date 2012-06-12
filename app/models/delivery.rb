class Delivery < ActiveRecord::Base
  belongs_to :order
  belongs_to :delivery_list
  belongs_to :route
  belongs_to :package

  has_one :distributor, through: :delivery_list
  has_one :box,         through: :order
  has_one :account,     through: :order
  has_one :address,     through: :order
  has_one :customer,    through: :order

  has_many :payments,   as: :payable
  has_many :deductions, as: :deductable

  acts_as_list scope: [:delivery_list_id, :route_id]

  attr_accessible :order, :order_id, :route, :status, :status_change_type, :delivery_list, :package, :package_id, :account

  STATUS_CHANGE_TYPE = %w(manual auto)

  validates_presence_of :order_id, :delivery_list_id, :route_id, :package_id, :status, :status_change_type
  validates_inclusion_of :status_change_type, in: STATUS_CHANGE_TYPE, message: "%{value} is not a valid status change type"

  before_validation :default_route, if: 'route.nil?'

  before_create :add_delivery_number

  scope :pending,   where(status: 'pending')
  scope :delivered, where(status: 'delivered')
  scope :cancelled, where(status: 'cancelled')

  default_value_for :status_change_type, 'auto'

  delegate :date, to: :delivery_list, allow_nil: true

  state_machine :status, initial: :pending do
    before_transition on: :deliver, do: :deduct_account
    before_transition on: [:pend, :cancel], do: :reverse_deduction

    event :pend do
      transition all - :pending => :pending
    end

    event :cancel do
      transition all - :cancelled => :cancelled
    end

    event :deliver do
      transition all - :delivered => :delivered
    end
  end

  def self.auto_deliver(delivery)
    auto_delivered = false

    unless delivery.status_change_type == 'manual'
      delivery.status_change_type = 'auto'
      delivery.status_event = 'deliver'

      auto_delivered = delivery.save
    end

    return auto_delivered
  end

  def self.change_statuses(deliveries, new_status, options = {})
    result = deliveries.all? do |delivery|
      delivery.status_event = new_status
      delivery.save
    end

    return result
  end

  def self.pay_on_delivery(deliveries)
    payment_date = Date.current

    deliveries.each do |delivery|
      unless delivery.paid?
        delivery.payments.create(
          distributor: delivery.distributor,
          account: delivery.account,
          amount: delivery.package.price,
          kind: 'delivery',
          source: 'pay_on_delivery',
          description: "Payment on delivery - #{payment_date.to_s(:transaction)}",
          payment_date: payment_date
        )
      end
    end
  end

  def self.reverse_pay_on_delivery(deliveries)
    deliveries.each do |delivery|
      delivery.payment.reverse_payment! if delivery.paid?
    end
  end

  def payment
    @payment ||= payments.order(:created_at).last
  end

  def deduction
    @deduction ||= deductions.order(:created_at).last
  end

  def paid?
    !payment.nil? && !payment.reversed
  end

  def deducted?
    !deduction.nil? && !deduction.reversed
  end

  def quantity
    package.archived_order_quantity
  end

  def future_status?
    pending? # This is the only status that is valid for deliveries in the future
  end

  def reposition!(position)
    update_attribute(:position, position)
  end

  def description
    "Delivery of #{package.contents_description} at #{package.price} each."
  end

  # TODO: Not sure if this fits in the model might need to go in Delivery CSV model down the road
  def self.csv_headers
    [
      'Delivery Route', 'Delivery Sequence Number', 'Delivery Pickup Point Name',
      'Order Number', 'Delivery Number', 'Delivery Date', 'Customer Number', 'Customer First Name',
      'Customer Last Name', 'Customer Phone', 'New Customer', 'Delivery Address Line 1', 'Delivery Address Line 2',
      'Delivery Address Suburb', 'Delivery Address City', 'Delivery Address Postcode', 'Delivery Note',
      'Box Contents Short Description', 'Price'
    ]
  end

  def to_csv
    [
      route.name,
      (position ? ("%03d" % position) : nil),
      nil,
      order.id,
      id,
      date.strftime("%-d %b %Y"),
      customer.number,
      customer.first_name,
      customer.last_name,
      address.phone_1,
      (customer.new? ? 'NEW' : nil),
      address.address_1,
      address.address_2,
      address.suburb,
      address.city,
      address.postcode,
      address.delivery_note,
      order.string_sort_code,
      package.price
    ]
  end

  private

  def default_route
    self.route = order.route if order
  end

  def add_delivery_number
    self.delivery_number = self.position
  end

  def deduct_account
    unless self.deducted?
      self.deductions.build(
        distributor: distributor,
        account: account,
        amount: package.price,
        kind: 'delivery',
        source: 'delivery',
        description: 'Delivery was made.'
      )
    end
  end

  def reverse_deduction
    self.deduction.reverse_deduction! if self.deducted?
  end

  def customer_callback
    Event.create_call_reminder(customer)
  end

  def remove_from_schedule
    unless new_delivery
      errors.add(:base, 'There is no "new delivery" to remove from the schedule so this status change can not be completed.')
    end

    unless new_delivery && new_delivery.destroy
      errors.add(:base, 'The delivery could not be destroyed.')
    end

    unless order.save
      errors.add(:base, 'The order could not be saved.')
    end
  end

  def add_to_schedule
    unless new_delivery
      errors.add(:base, 'There is no "new delivery" to add to the schedule so this status change can not be completed.')
    end

    unless order.save
      errors.add(:base, 'The order could not be saved.')
    end
  end
end

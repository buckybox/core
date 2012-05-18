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

  has_many :transactions, as: :transactionable

  acts_as_list scope: [:delivery_list_id, :route_id]

  attr_accessible :order, :order_id, :route, :status, :status_change_type, :delivery_list, :package, :package_id, :account

  STATUS = %w(pending delivered cancelled rescheduled repacked)
  STATUS_CHANGE_TYPE = %w(manual auto)

  validates_presence_of :order_id, :delivery_list_id, :route_id, :package_id, :status
  validates_inclusion_of :status, in: STATUS, message: "%{value} is not a valid status"
  validates_inclusion_of :status_change_type, in: STATUS_CHANGE_TYPE, message: "%{value} is not a valid status change type"

  before_validation :default_route, if: 'route.nil?'
  before_validation :changed_status, if: 'status_changed?'

  before_create :add_delivery_number

  scope :pending,     where(status: 'pending')
  scope :delivered,   where(status: 'delivered')
  scope :cancelled,   where(status: 'cancelled')
  scope :rescheduled, where(status: 'rescheduled')
  scope :repacked,    where(status: 'repacked')

  default_value_for :status, 'pending'
  default_value_for :status_change_type, 'auto'

  delegate :date, to: :delivery_list, allow_nil: true

  def self.change_statuses(deliveries, new_status, options = {})
    return false unless STATUS.include?(new_status)
    return false if (new_status == 'rescheduled' || new_status == 'repacked') && options[:date].nil?

    result = deliveries.all? do |delivery|
      delivery.status = new_status
      delivery.save
    end

    return result
  end

  def self.auto_deliver(delivery)
    auto_delivered = false

    unless delivery.status_change_type == 'manual'
      delivery.status = 'delivered'
      delivery.status_change_type = 'auto'

      auto_delivered = delivery.save
    end

    return auto_delivered
  end

  def quantity
    package.archived_order_quantity
  end

  def future_status?
    status == 'pending' # This is the only status that is valid for deliveries in the future
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

  def paid_on_delivery
    # Essentially a distributor "beez in the trap" (http://youtu.be/VY0cDbb5A_8?t=7m7s) here
  end

  private

  def default_route
    self.route = order.route
  end

  def add_delivery_number
    self.delivery_number = self.position
  end

  def changed_status
    old_status, new_status = self.status_change

    subtract_from_account if new_status == 'delivered'
    add_to_account        if old_status == 'delivered'

    Event.create_call_reminder(customer) if new_status == 'delivered' && customer.new?
  end

  def subtract_from_account
    account.subtract_from_balance(
      package.price,
      transactionable: self,
      description: "Delivery was made of #{package.contents_description} at #{package.price}."
    )
    errors.add(:base, 'Problem subtracting balance from account on delivery status change.') unless account.valid?
  end

  def add_to_account
    account.add_to_balance(
      package.price,
      transactionable: self,
      description: "Delivery reversal. #{package.contents_description} at #{package.price}."
    )
    errors.add(:base, 'Problem adding balance from account on delivery status change.') unless account.valid?
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

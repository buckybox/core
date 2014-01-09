class Delivery < ActiveRecord::Base
  belongs_to :order
  belongs_to :delivery_list
  belongs_to :delivery_service
  belongs_to :package

  has_one :distributor, through: :delivery_list
  has_one :box,         through: :order
  has_one :account,     through: :order
  has_one :address,     through: :order
  has_one :customer,    through: :order

  has_many :payments,   as: :payable
  has_many :deductions, as: :deductable

  acts_as_list scope: [:delivery_list_id, :delivery_service_id]

  attr_accessible :order, :order_id, :delivery_service, :status, :status_change_type, :delivery_list, :package, :package_id, :account

  STATUS_CHANGE_TYPE = %w(manual auto)

  validates_presence_of :order_id, :delivery_list_id, :delivery_service_id, :package_id, :status, :status_change_type
  validates_inclusion_of :status_change_type, in: STATUS_CHANGE_TYPE, message: "%{value} is not a valid status change type"

  before_validation :default_delivery_service, if: 'delivery_service.nil?'

  before_save :update_dso
  before_create :set_delivery_number
  after_save :tracking

  scope :pending,   where(status: 'pending')
  scope :delivered, where(status: 'delivered')
  scope :cancelled, where(status: 'cancelled')
  scope :ordered, order('dso ASC, created_at ASC')

  default_value_for :status_change_type, 'auto'

  delegate :date, to: :delivery_list, allow_nil: true
  delegate :address_hash, to: :address
  delegate :archived?, to: :delivery_list, allow_nil: true

  STATUS_TO_EVENT = {'pending' => 'pend', 'cancelled' => 'cancel', 'delivered' => 'deliver'}

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
    return true if delivery.delivered? || delivery.manual?

    delivery.status_change_type = 'auto'
    delivery.status_event = 'deliver'
    delivery.save
  end

  def self.change_statuses(deliveries, status_event)
    deliveries.all? do |delivery|
      result = delivery.already_performed_event?(status_event)

      unless result
        delivery.status_event = status_event
        delivery.status_change_type = 'manual'
        result = delivery.save
      end

      result
    end
  end

  def self.pay_on_delivery(deliveries)
    deliveries.each do |delivery|
      unless delivery.paid?
        delivery.payments.create(
          distributor: delivery.distributor,
          account: delivery.account,
          amount: delivery.payment_amount,
          kind: 'delivery',
          source: 'manual',
          description: 'Payment made on delivery',
          display_time: delivery.date.to_time_in_current_zone
        )
      end
    end
  end

  def self.reverse_pay_on_delivery(deliveries)
    deliveries.each do |delivery|
      delivery.payment.reverse_payment! if delivery.paid?
    end
  end

  def status_formatted
    status # in future the output may not match our internal status
  end

  def already_performed_event?(status_event)
    STATUS_TO_EVENT[self.status.to_s] == status_event.to_s
  end

  def formated_delivery_number
    "%03d" % delivery_number.to_i
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

  def manual?
    status_change_type == 'manual'
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

  def reposition_dso!(dso)
    update_attribute(:dso, dso)
  end

  def description
    desc_str = (quantity > 1 ? "(#{quantity}x) " : '')
    desc_str += package.contents_description

    return desc_str
  end

  def self.matching_dso(delivery_sequence_order)
    delivery_ids = Delivery.joins({delivery_list:{}, account: {customer: {address: {}}}}).where(['deliveries.delivery_service_id = ? AND addresses.address_hash = ? AND EXTRACT(DOW FROM delivery_lists.date) = ?', delivery_sequence_order.delivery_service_id, delivery_sequence_order.address_hash, delivery_sequence_order.day]).collect(&:id)
    Delivery.where(['id in (?)', delivery_ids])
  end

  def update_dso
    self.dso = DeliverySequenceOrder.for_delivery(self).position
  end

  def set_delivery_number
    update_dso
    self.delivery_number = delivery_list.get_delivery_number(self)
  end

  def payment_amount
    package.total_price
  end

  def consumer_delivery_fee_cents
    package.archived_consumer_delivery_fee_cents
  end

private

  def default_delivery_service
    self.delivery_service = order.delivery_service if order
  end

  def deduct_account
    source = 'manual'

    if self.status_change_type_changed? && self.status_change_type_change.last == 'auto'
      source = 'auto' 
    end

    unless self.deducted?
      self.deductions.build(
        distributor: distributor,
        account: account,
        amount: package.price,
        kind: 'delivery',
        source: source,
        description: "Delivery of #{description}",
        display_time: date.to_time_in_current_zone
      )
    end
  end

  def reverse_deduction
    self.deduction.reverse_deduction! if self.deducted?
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

  def tracking
    if status_changed? && status == 'delivered'
      Bucky::Tracking.instance.event(distributor, "distributor_delivered_order")
      Bucky::Tracking.instance.event(distributor, "engaged")
    end
  end
end

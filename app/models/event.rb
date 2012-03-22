class Event < ActiveRecord::Base
  belongs_to :distributor

  # Setup accessible (or protected) attributes for your model
  attr_accessible :distributor_id, :event_category, :event_type, :customer_id, :invoice_id, :reconciliation_id,
    :transaction_id, :delivery_id, :dismissed, :trigger_on

  # Global variables
  EVENT_CATEGORIES = %w(customer billing delivery)
  EVENT_TYPES = {
    customer_new:             'customer_new',
    customer_call_reminder:   'customer_call_reminder',
    delivery_scheduler_issue: 'delivery_scheduler_issue',
    delivery_pending:         'delivery_pending',
    credit_limit_reached:     'credit_limit_reached',
    payment_overdue:          'payment_overdue',
    invoice_reminder:         'invoice_reminder',
    invoice_mail_sent:        'invoice_mail_sent',
    transaction_success:      'transaction_success',
    transaction_failure:      'transaction_failure'
  }

  validates_presence_of :distributor_id
  validates_presence_of :customer_id,       if: :requires_customer?
  validates_presence_of :delivery_id,       if: :requires_delivery?
  validates_presence_of :invoice_id,        if: :requires_invoice?
  validates_presence_of :reconciliation_id, if: :requires_reconciliation?
  validates_presence_of :transaction_id,    if: :requires_transaction?

  validates_inclusion_of :event_category, in: EVENT_CATEGORIES
  validates_inclusion_of :event_type,     in: EVENT_TYPES.values

  before_save :check_trigger

  scope :active,  where(dismissed: false)
  scope :current, lambda { where('trigger_on <= ?', Time.current) }

  default_scope order('trigger_on DESC')

  def dismiss!
    update_attribute('dismissed', true)
  end

  def self.trigger(distributor_id, event_type, params = {})
    # TODO resolve event_category based on event_type (instead of passing it as a param everytime the method is called)
    create( { distributor_id: distributor_id, event_type: event_type }.merge!(params) )
  end

  def self.new_customer(customer)
    trigger(
      customer.distributor_id,
      Event::EVENT_TYPES[:customer_new],
      { event_category: 'customer', customer_id: customer.id }
    )
  end

  def self.create_call_reminder(customer)
    trigger(
      customer.distributor.id,
      Event::EVENT_TYPES[:customer_call_reminder],
      { event_category: 'customer', customer_id: customer.id, trigger_on: (Time.current + 1.day) }
    )
  end

  # FIXME: There has to be a better way to do this using inheritance, dynamic method
  # or SOMETHING like that.
  def customer
    Customer.find(customer_id) if customer_id
  end

  def customer=(customer)
    self.customer_id = customer.id
  end

  def delivery
    Delivery.find(delivery_id) if delivery_id
  end

  def delivery=(delivery)
    self.delivery_id = delivery.id
  end

  def invoice
    Invoice.find(invoice_id) if invoice_id
  end

  def invoice=(invoice)
    self.invoice_id = invoice.id
  end

  def transaction
    Transaction.find(transaction_id) if transaction_id
  end

  def transaction=(transaction)
    self.transaction_id = transaction.id
  end

  private

  def check_trigger
    self.trigger_on = Time.current if self.trigger_on.nil?
  end

  def requires_customer?
    [
      EVENT_TYPES[:customer_new],
      EVENT_TYPES[:customer_call_reminder],
      EVENT_TYPES[:credit_limit_reached],
      EVENT_TYPES[:payment_overdue]
    ].include?(self.event_type)
  end

  def requires_delivery?
    [
      EVENT_TYPES[:delivery_scheduler_issue],
      EVENT_TYPES[:delivery_pending]
    ].include?(self.event_type)
  end

  def requires_invoice?
    [
      EVENT_TYPES[:invoice_reminder],
      EVENT_TYPES[:invoice_mail_sent]
    ].include?(self.event_type)
  end

  def requires_reconciliation?
    [
      EVENT_TYPES[:invoice_reminder]
    ].include?(self.event_type)
  end

  def requires_transaction?
    [
      EVENT_TYPES[:transaction_success],
      EVENT_TYPES[:transaction_failure]
    ].include?(self.event_type)
  end
end

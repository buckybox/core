class Event < ActiveRecord::Base

  belongs_to :distributor

  # Setup accessible (or protected) attributes for your model
  attr_accessible :distributor_id, :event_category, :event_type, :customer_id, :invoice_id, :reconciliation_id, :transaction_id, :dismissed

  # Global variables
  EVENT_CATEGORIES = %w[customer billing delivery]
  EVENT_TYPES= 
    %w[
      customer_new
      customer_call_reminder
      delivery_scheduler
      issue delivery_pending
      credit_limit_reached
      payment_overdue
      invoice_reminder
      invoice_mail_sent
      transaction_success
      transaction_failure
    ]

  validates_presence_of :distributor_id
  validates_inclusion_of :event_category, :in => EVENT_CATEGORIES
  validates_inclusion_of :event_type, :in => EVENT_TYPES

  scope :sorted, order("events.created_at DESC")
  scope :dismissed, where("events.dismissed = ?", true)
  scope :active, where("events.dismissed = ?", false)
end

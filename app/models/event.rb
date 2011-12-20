class Event < ActiveRecord::Base

  belongs_to :distributor

  # Setup accessible (or protected) attributes for your model
  attr_accessible :event_category

  # Global variables
  EVENT_CATEGORIES = %w[customer billing delivery]
  EVENT_TYPES= %w[customer_new customer_call_reminder invoice_reminder invoice_mail_sent transaction_success transaction_failure delivery_pending]

  validates_inclusion_of :event_category, :in => EVENT_CATEGORIES
  validates_inclusion_of :event_type, :in => EVENT_TYPES

  scope :sorted, order("events.created_at DESC")
  scope :dismissed, where("events.dismissed = ?", true)
  scope :active, !dismissed
end

class Event < ActiveRecord::Base

  belongs_to :distributor

  # Setup accessible (or protected) attributes for your model
  attr_accessible :distributor_id, :event_category, :event_type, :customer_id, :invoice_id, :reconciliation_id, :transaction_id, :delivery_id, :dismissed

  # Global variables
  EVENT_CATEGORIES = %w[customer billing delivery]
  EVENT_TYPES = { 
      :customer_new              => "customer_new",
      :customer_call_reminder    => "customer_call_reminder",
      :delivery_scheduler_issue  => "delivery_scheduler_issue",
      :delivery_pending          => "delivery_pending",
      :credit_limit_reached      => "credit_limit_reached",
      :payment_overdue           => "payment_overdue",
      :invoice_reminder          => "invoice_reminder",
      :invoice_mail_sent         => "invoice_mail_sent",
      :transaction_success       => "transaction_success",
      :transaction_failure       => "transaction_failure"
  }

  validates_presence_of :distributor_id
  validates_presence_of :customer_id, :if => lambda{[
      EVENT_TYPES[:customer_new],
      EVENT_TYPES[:customer_call_reminder],
      EVENT_TYPES[:credit_limit_reached],
      EVENT_TYPES[:payment_overdue]
  ].include? event_type}
  validates_presence_of :delivery_id, :if => lambda{[
    EVENT_TYPES[:delivery_scheduler_issue],
    EVENT_TYPES[:delivery_pending]].include? event_type}
  validates_presence_of :invoice_id, :if => lambda{[
    EVENT_TYPES[:invoice_reminder], 
    EVENT_TYPES[:invoice_mail_sent]].include? event_type}
  validates_presence_of :reconciliation_id, :if => lambda{[
    EVENT_TYPES[:invoice_reminder]].include? event_type}
  validates_presence_of :transaction_id, :if => lambda{[
    EVENT_TYPES[:transaction_success], 
    EVENT_TYPES[:transaction_failure]].include? event_type}

  validates_inclusion_of :event_category, :in => EVENT_CATEGORIES
  validates_inclusion_of :event_type, :in => EVENT_TYPES.map{|k,v| v}

  scope :sorted, order("events.created_at DESC")
  scope :active, where("events.dismissed = ?", false)

  def dismiss!
    update_attribute("dismissed", true)
  end

  private
  def self.trigger(distributor_id, event_type, params = {})
    # TODO resolve event_category based on event_type (instead of passing it as a param everytime the method is called)
    self.create({distributor_id: distributor_id, event_type: event_type}.merge!(params))
  end
end

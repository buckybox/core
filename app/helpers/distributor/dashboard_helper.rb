module Distributor::DashboardHelper
  def notification_message_for notification
    case notification.event_type
      when Event::EVENT_TYPES[:customer_new]
        # TODO Show address and Add dropdown to assign delivery address
        customer = Customer.find notification.customer_id
        "New customer #{link_to_customer customer}".html_safe

      when Event::EVENT_TYPES[:customer_call_reminder]
        customer = Customer.find notification.customer_id
        "Follow up call #{link_to_customer customer}".html_safe

      when Event::EVENT_TYPES[:delivery_scheduler_issue]
        "Delivery Scheduler could not schedule a #{link_to_delivery notification.delivery_id}".html_safe

      when Event::EVENT_TYPES[:delivery_pending]
        "A #{link_to_delivery notification.delivery_id} is still marked as pending".html_safe

      when Event::EVENT_TYPES[:credit_limit_reached]
        # TODO This is the message that should appear when the limit is reached. If limit continues to be exceded next days display "Credit Limit continues to be exceeded for [CUSTOMER NAME/ID]" instead
        customer = Customer.find notification.customer_id
        "Credit Limit reached for #{link_to_customer customer}, deliveries will be halted".html_safe

      when Event::EVENT_TYPES[:payment_overdue]
        customer = Customer.find notification.customer_id
        "Payment overdue for #{link_to_customer customer}".html_safe

      when Event::EVENT_TYPES[:invoice_reminder]
        "#{link_to_invoice notification.invoice_id} will be sent tomorrow, please #{link_to_reconciliation notification.reconciliation_id} (payments overdue)".html_safe

      when Event::EVENT_TYPES[:invoice_mail_sent]
        "#{link_to_invoice notification.invoice_id} has been sent by email".html_safe

      when Event::EVENT_TYPES[:transaction_success]
        transaction = Transaction.find notification.transaction_id
        "#{link_to_transaction transaction.id} was successfully made (#{transaction.amount})".html_safe

      when Event::EVENT_TYPES[:transaction_failure]
        transaction = Transaction.find notification.transaction_id
        "#{link_to_transaction transaction.id} declined, will try again next week (#{transaction.amount})".html_safe
    end
  end

  def link_to_customer customer
      link_to_customer = link_to "#{customer.name} (##{customer.id})", customer_path(customer.id)
  end

  def link_to_delivery delivery_id
    link_to  "delivery", distributor_delivery_path(current_distributor, delivery_id)
  end

  def link_to_invoice invoice_id
    #TODO change the path to match the correct route when invoice page created
    #link_to  "Invoice ##{invoice_id}", distributor_invoice_path(current_distributor, invoice_id)
    "An invoice"
  end

  def link_to_transaction transaction_id
    link_to "Transaction ##{transaction_id}", distributor_transaction_path(current_distributor, transaction_id)
  end

  def link_to_reconciliation reconciliation_id
    #TODO change the path to match the correct route when invoice page created
    #link_to  "reconcile bank deposits", distributor_reconciliation_path(current_distributor, reconciliation_id)
    "reconcile bank deposits"
  end


  def date_for notification
    notification.created_at.strftime("%d %B")
  end
end

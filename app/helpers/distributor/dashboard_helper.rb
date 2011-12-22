module Distributor::DashboardHelper
  def notification_message_for notification
    case notification.event_type
      # TODO add links to relevant pages
      when Event::EVENT_TYPES[:customer_new]
        # TODO Add dropdown to assign delivery address
        customer = Customer.find notification.customer_id
        "New customer #{customer.name}(##{customer.id})"

      when Event::EVENT_TYPES[:customer_call_reminder]
        customer = Customer.find notification.customer_id
        "First delivery follow up call #{customer.name}(##{customer.id})"
      when Event::EVENT_TYPES[:delivery_scheduler_issue]
        # TODO link to the delivery when deliveries created
        "Delivery Scheduler could not schedule a delivery [#{notification.delivery_id}]}"

      when Event::EVENT_TYPES[:delivery_pending]
        # TODO adapt to whatever the Delivery is gonna look like
        "A delivery [#{notification.delivery_id}] is still marked as pending"

      when Event::EVENT_TYPES[:credit_limit_reached]
        # TODO This is the message that should appear when the limit is reached. If limit continues to be exceded next days display "Credit Limit continues to be exceeded for [CUSTOMER NAME/ID]" instead
        customer = Customer.find notification.customer_id
        "Credit Limit reached for #{customer.name}(##{customer.id}), deliveries will be halted"

      when Event::EVENT_TYPES[:payment_overdue]
        customer = Customer.find notification.customer_id
        "Payment overdue for #{customer.name}(##{customer.id})"

      when Event::EVENT_TYPES[:invoice_reminder]
        "Invoice ##{notification.invoice_id} will be sent tomorrow, please [reconcile bank deposits #{notification.reconciliation_id}] (payments overdue)"

      when Event::EVENT_TYPES[:invoice_mail_sent]
        "Invoice ##{notification.invoice_id} has been sent by email"

      when Event::EVENT_TYPES[:transaction_success]
        transaction = Transaction.find notification.transaction_id
        "Transaction ##{transaction.id} was successfully made (#{transaction.amount})"

      when Event::EVENT_TYPES[:transaction_failure]
        transaction = Transaction.find notification.transaction_id
        "Transaction ##{transaction.id} declined, will try again next week (#{transaction.amount})"
    end
  end

  def date_for notification
    notification.created_at.strftime("%d %B")
  end
end

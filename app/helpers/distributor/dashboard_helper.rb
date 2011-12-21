module Distributor::DashboardHelper
  def notification_message_for notification
    case notification.event_type
      # TODO add links to relevant pages
      when "customer_new"
        # TODO Add dropdown to assign delivery address
        customer = Customer.find notification.customer_id
        "New customer #{customer.name}(##{customer.id})"
      when "customer_call_reminder"
        customer = Customer.find notification.customer_id
        "First delivery follow up call #{customer.name}(##{customer.id})"
      when "delivery_scheduler"
        # TODO link to the delivery when deliveries created
        "Delivery Scheduler could not schedule a delivery [#{delivery_id}]}"
      when "issue delivery_pending"
        # TODO adapt to whatever the Delivery is gonna look like
        #delivery = Delivery.find notification.delivery_id
      when "credit_limit_reached"
        # TODO This is the message that should appear when the limit is reached. If limit continues to be exceded next days display "Credit Limit continues to be exceeded for [CUSTOMER NAME/ID]" instead
        customer = Customer.find notification.customer_id
        "Credit Limit reached for #{customer.name}(##{customer.id}), deliveries will be halted"
      when "payment_overdue"
        cutsomer = Customer.find notification.customer_id
        "Payment overdue for #{cutomer.name}(##{customer.id})"
      when "invoice_reminder"
        "Invoice ##{notification.invoice_id} will be sent tomorrow, please [reconcile bank deposits #{notification.reconciliation_id}] as some payments are overdue"
      when "invoice_mail_sent"
        "Invoice ##{notification.invoice_id} has been sent by email"
      when "transaction_success"
        transaction = Transaction.find notification.transaction_id
        "Transaction ##{transaction.id} was successfully made (#{transaction.amount})"
      when "transaction_failure"
        transaction = Transaction.find notification.transaction_id
        "Transaction ##{transaction.id} declined, will try again next week (#{transaction.amount})"
    end
  end

  def date_for notification
    notification.created_at.strftime("%d %B")
  end
end

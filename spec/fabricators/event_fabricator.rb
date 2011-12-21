Fabricator(:customer_event, :from => :event) do
  distributor!
  event_category { "customer" }
  event_type { Event::EVENT_TYPES[:customer_new] }
  customer_id 1
end

Fabricator(:billing_event, :from => :event) do
  distributor!
  event_category { "billing" }
  event_type { Event::EVENT_TYPES[:invoice_reminder] }
  invoice_id 1
  reconciliation_id 1
end

Fabricator(:delivery_event, :from => :event) do
  distributor!
  event_category { "delivery" }
  event_type { Event::EVENT_TYPES[:delivery_pending] }
  customer_id 1
end

Fabricator(:customer_event, :from => :event) do
  distributor!
  event_category { "customer" }
  event_type { "customer_new" }
  customer_id 1
end

Fabricator(:billing_event, :from => :event) do
  distributor!
  event_category { "billing" }
  event_type { "invoice_reminder" }
  invoice_id 1
end

Fabricator(:delivery_event, :from => :event) do
  distributor!
  event_category { "delivery" }
  event_type { "delivery_pending" }
  customer_id 1
end

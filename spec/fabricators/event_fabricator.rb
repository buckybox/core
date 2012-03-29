Fabricator(:customer_event, from: :event) do
  customer!
  distributor! { |event| event.customer.distributor }
  event_category { 'customer' }
  event_type { 'customer_new' }
end

Fabricator(:billing_event, from: :event) do
  invoice!
  distributor! { |event| event.invoice.distributor }
  reconciliation_id 1
  event_category { 'billing' }
  event_type { 'invoice_reminder' }
end

Fabricator(:delivery_event, from: :event) do
  delivery!
  distributor! { |event| event.delivery.distributor }
  event_category { 'delivery' }
  event_type { 'delivery_pending' }
end

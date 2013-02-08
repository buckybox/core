Fabricator(:customer_event, from: :event) do
  customer
  distributor { |attrs| attrs[:customer].distributor }
  event_category { 'customer' }
  event_type { 'customer_new' }
end

Fabricator(:billing_event, from: :event) do
  invoice
  distributor { |attrs| attrs[:invoice].distributor }
  reconciliation_id 1
  event_category { 'billing' }
  event_type { 'invoice_reminder' }
end

Fabricator(:delivery_event, from: :event) do
  delivery
  distributor { |attrs| attrs[:delivery].distributor }
  event_category { 'delivery' }
  event_type { 'delivery_pending' }
end

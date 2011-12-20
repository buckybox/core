Fabricator(:customer_event, :from => :event) do
  distributor!
  event_category { "customer" }
end

Fabricator(:billing_event, :from => :event) do
  distributor!
  event_category { "billing" }
end

Fabricator(:delivery_event, :from => :event) do
  distributor!
  event_category { "delivery" }
end

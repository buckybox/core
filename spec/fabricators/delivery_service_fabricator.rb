Fabricator(:delivery_service) do
  distributor
  schedule_rule
  name { sequence(:name) { |i| "DeliveryService #{i}" } }
  fee 0
  instructions 'Services all of the areas.'
end

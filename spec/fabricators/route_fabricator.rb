Fabricator(:route) do
  distributor
  schedule_rule
  name { sequence(:name) { |i| "Route #{i}" } }
  fee 0
  area_of_service 'Services all of the areas.'
  estimated_delivery_time 'Between 9am and 5pm.'
end

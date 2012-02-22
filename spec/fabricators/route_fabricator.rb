Fabricator(:route) do
  distributor!
  name { sequence(:name) { |i| "Route #{i}" } }
  fee 0
  monday true
end

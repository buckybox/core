Fabricator(:route) do
  distributor!
  name { sequence(:name) { |i| "Route #{i}" } }
  monday true
end

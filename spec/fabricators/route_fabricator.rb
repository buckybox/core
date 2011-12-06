Fabricator(:route) do
  distributor!
  name { sequence(:name) { |i| "Route #{i}" } }
end

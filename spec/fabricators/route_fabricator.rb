Fabricator(:route) do
  distributor!
  name { sequence(:name) { |i| "Route #{i}" } }
  fee 0
  monday true
  tuesday true
  wednesday true
  thursday true
  friday true
  saturday true
  sunday true
  start_time { Time.current.beginning_of_day - 2.years } # Making this ages ago so that orders validate against it
end

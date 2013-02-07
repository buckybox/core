Fabricator(:extra) do
  distributor
  name { sequence(:name) { |i| "Extra #{i}" } }
  unit 'single'
  price 295
end

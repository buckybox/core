Fabricator(:box) do
  distributor!
  name { sequence(:name) { |i| "Box #{i}" } }
  description { sequence(:description) { |i| "Description #{i}" } }
  price 10
end

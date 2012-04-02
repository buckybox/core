Fabricator(:extra) do
  name { sequence(:name) { |i| "Extra #{i}" } }
  unit "single"
  distributor { Fabricate.build(:distributor)}
  price 295
end

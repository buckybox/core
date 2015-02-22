Fabricator(:localised_address) do
  street { sequence(:street) { |i| "#{i} St" } }
  city { sequence(:city) { |i| "City #{i}" } }
end

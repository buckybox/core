Fabricator(:address) do
  customer!
  address_1 { sequence(:address_1) { |i| "#{1} Address St" } }
  suburb { sequence(:suburb) { |i| "Suburb #{i}" } }
  city { sequence(:city) { |i| "City #{i}" } }
  postcode { sequence(:psotcode, 1000) }
end

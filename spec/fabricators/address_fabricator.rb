Fabricator(:address) do
  customer
  address_1 { sequence(:address_1) { |i| "#{i} Address St" } }
  suburb { 'Suburb' }
  city { 'City' }
end

Fabricator(:address_with_associations, from: :address) do
  customer
end

Fabricator(:full_address, from: :address) do
  address_2 { 'Apartment 1' }
  postcode { '00000' }
  delivery_note { 'This is a note.' }
  mobile_phone { '11-111-111-1111' }
  home_phone { '22-222-222-2222' }
  work_phone { '33-333-333-3333' }
end


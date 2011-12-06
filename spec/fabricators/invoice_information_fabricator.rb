Fabricator(:invoice_information) do
  distributor!
  gst_number { sequence(:gst_number) }
  billing_address_1 { sequence(:billing_address_1) { |i| "#{1} Invoice Information St" } }
  billing_suburb { sequence(:billing_suburb) { |i| "Suburb #{i}" } }
  billing_city { sequence(:billing_city) { |i| "City #{i}" } }
  billing_postcode { sequence(:billing_postcode, 1000) }
  phone { sequence(:phone, 1000000000) }
end

Fabricator(:invoice_information) do
  distributor
  gst_number 1
  billing_address_1 '1 Invoice Information St'
  billing_suburb 'Suburb'
  billing_city 'City'
  billing_postcode 1
  phone 1
end

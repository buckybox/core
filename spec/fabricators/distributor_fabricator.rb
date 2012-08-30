Fabricator(:distributor) do
  name { sequence(:name) { |i| "Distributor #{i}" } }
  email { sequence(:email) { |i| "distributor#{i}@example.com" } }
  password 'password'
  password_confirmation { |distributor| distributor.password }
  country
  consumer_delivery_fee 0.20
end

Fabricator(:distributor_with_information, from: :distributor) do
  invoice_information!
  bank_information!
end

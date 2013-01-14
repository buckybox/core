Fabricator(:distributor) do
  name { sequence(:name) { |i| "Distributor #{i}" } }
  email { sequence(:email) { |i| "distributor#{i}@example.com" } }
  password 'password'
  password_confirmation { |attrs| attrs[:password] }
  country
  consumer_delivery_fee_cents 0
end

Fabricator(:distributor_with_information, from: :distributor) do
  invoice_information
  bank_information
end

Fabricator(:distributor_a_customer, from: :distributor) do
  after_create {|distributor| distributor.customers << Fabricate(:customer, distributor: distributor)}
end

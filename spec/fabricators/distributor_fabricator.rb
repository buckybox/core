Fabricator(:distributor) do
  invoice_information! { |distributor| Fabricate(:invoice_information, :distributor => distributor) }
  bank_information! { |distributor| Fabricate(:bank_information, :distributor => distributor) }
  name { sequence(:name) { |i| "Distributor #{i}" } }
  email { sequence(:email) { |i| "distributor#{i}@example.com" } }
  password 'password'
  password_confirmation { |distributor| distributor.password }
end

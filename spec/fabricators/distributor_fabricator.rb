Fabricator(:distributor) do
  name { sequence(:name) { |i| "Distributor #{i}" } }
  email { sequence(:email) { |i| "distributor#{i}@example.com" } }
  password 'password'
  password_confirmation { |distributor| distributor.password }
end

Fabricator(:distributor_with_information, :from => :distributor) do
  invoice_information!
  bank_information!
end

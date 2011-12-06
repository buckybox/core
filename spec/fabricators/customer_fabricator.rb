Fabricator(:customer) do
  first_name { sequence(:first_name) { |i| "First Name #{i}" } }
  last_name { sequence(:last_name) { |i| "Last Name #{i}" } }
  email { sequence(:email) { |i| "customer#{i}@example.com" } }
end

Fabricator(:customer) do
  distributor!
  route!
  first_name { sequence(:first_name) { |i| "First Name #{i}" } }
  email { sequence(:email) { |i| "customer#{i}@example.com" } }
  password 'password'
  password_confirmation { |customer| customer.password }
  after_create { |customer| Fabricate(:account, :customer => customer) }
  after_create { |customer| Fabricate(:address, :customer => customer) }
end

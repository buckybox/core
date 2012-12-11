Fabricator(:customer_without_after_create, class_name: :customer) do
  distributor!
  route! { |customer| Fabricate(:route, distributor: customer.distributor) }
  first_name { sequence(:first_name) { |i| "First Name #{i}" } }
  email { sequence(:email) { |i| "customer#{i}@example.com" } }
  password 'password'
  password_confirmation { |customer| customer.password }
end

Fabricator(:customer, from: :customer_without_after_create) do
  after_create { |customer| Fabricate(:account, customer: customer) }
  after_build { |customer| Fabricate(:address_with_associations, customer: customer) }
end

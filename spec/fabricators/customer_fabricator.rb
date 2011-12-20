Fabricator(:customer) do
  distributor!
  account! {|customer| Fabricate(:account, :distributor => customer.distributor, :customer => customer)}
  first_name { sequence(:first_name) { |i| "First Name #{i}" } }
  last_name { sequence(:last_name) { |i| "Last Name #{i}" } }
  email { sequence(:email) { |i| "customer#{i}@example.com" } }
end

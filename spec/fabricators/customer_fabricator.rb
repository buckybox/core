Fabricator(:customer) do
  distributor!
  route!
  first_name { sequence(:first_name) { |i| "First Name #{i}" } }
  email { sequence(:email) { |i| "customer#{i}@example.com" } }
end

Fabricator(:customer_with_account, :from => :customer) do
  account! {|customer| Fabricate(:account, :distributor => customer.distributor, :customer => customer)}
end

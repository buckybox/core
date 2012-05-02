Fabricator(:bank_information) do
  distributor!
  name { sequence(:name) { |i| "Bank #{i}" } }
  account_name { sequence(:account_name) { |i| "Account Name #{i}" } }
  account_number { sequence(:account_number) }
  customer_message { sequence(:customer_message) { |i| "Message #{i}" } }
end

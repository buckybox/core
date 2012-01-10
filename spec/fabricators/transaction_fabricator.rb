Fabricator(:transaction) do
  account!
  kind 'delivery'
  amount 1000
  description { sequence(:description) { |i| "Description #{i}" } }
end

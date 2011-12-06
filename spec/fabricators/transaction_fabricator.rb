Fabricator(:transaction) do
  account!
  kind 'order'
  amount 1000
  description { sequence(:description) { |i| "Description #{i}" } }
end

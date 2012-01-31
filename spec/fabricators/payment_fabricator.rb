Fabricator(:payment) do
  distributor!
  account!
  amount 1000
  kind 'bank_transfer'
  description { sequence(:description) { |i| "Description #{i}" } }
end

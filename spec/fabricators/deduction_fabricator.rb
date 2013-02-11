Fabricator(:deduction) do
  distributor
  account
  amount 1000
  kind 'delivery'
  description 'descriptive text'
  deductable { Fabricate(:delivery) }
end

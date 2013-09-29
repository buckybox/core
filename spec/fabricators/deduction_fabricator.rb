Fabricator(:deduction) do
  distributor
  account
  amount 10
  kind 'delivery'
  description 'descriptive text'
  deductable { Fabricate(:delivery) }
end

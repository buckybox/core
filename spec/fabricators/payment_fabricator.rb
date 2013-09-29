Fabricator(:payment) do
  distributor
  account
  amount 10
  description 'descriptive text'
  payable { Fabricate(:delivery) }
end

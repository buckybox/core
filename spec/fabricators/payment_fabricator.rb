Fabricator(:payment) do
  distributor!
  account!
  amount 1000
  description 'descriptive text'
  payable! { Fabricate(:delivery) }
end

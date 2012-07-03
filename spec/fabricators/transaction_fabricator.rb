Fabricator(:transaction) do
  account!
  transactionable! { Fabricate(:payment) }
  amount 1000
  description 'descriptive text'
end

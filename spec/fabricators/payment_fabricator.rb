Fabricator(:payment) do
  distributor!
  account!
  amount 1000
  kind 'cash'
  description 'descriptive text'
  payment_date Date.current
  payable! { Fabricate(:delivery) }
end

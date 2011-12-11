Fabricator(:order) do
  distributor!
  box!
  customer!
  account!
  quantity 1
  frequency 'single'
end

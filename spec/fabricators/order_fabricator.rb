Fabricator(:order) do
  distributor!
  box!
  customer!
  quantity 1
  frequency 'single'
end

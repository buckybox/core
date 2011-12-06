Fabricator(:account) do
  distributor!
  customer!
  balance 0
end

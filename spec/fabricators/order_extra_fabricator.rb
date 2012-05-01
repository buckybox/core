Fabricator(:order_extra) do
  order { Fabricate(:order) }
  extra { Fabricate(:extra) }
  count 1
end

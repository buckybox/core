Fabricator(:delivery) do
  order!(:fabricator => :active_order)
  route!
  date Date.today - 1.day
end

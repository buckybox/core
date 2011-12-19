Fabricator(:delivery) do
  order!
  route!
  date Time.now
end

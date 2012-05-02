Fabricator(:delivery) do
  order!
  route!
  package!
  delivery_list!
end

Fabricator(:delivery) do
  order!
  route!
  delivery_list!
  package!
end

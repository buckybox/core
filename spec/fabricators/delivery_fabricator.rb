Fabricator(:delivery) do
  order!(fabricator: :order)
  route!
  delivery_list!
  package!
end

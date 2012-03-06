Fabricator(:delivery) do
  order!(fabricator: :active_order)
  route!
  delivery_list!
  package!
end

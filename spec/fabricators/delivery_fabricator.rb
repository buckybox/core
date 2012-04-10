Fabricator(:delivery) do
  order!
  route!
  package!
  delivery_list!(fabricator: :delivery_list_with_associations)
end

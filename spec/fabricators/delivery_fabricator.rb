Fabricator(:delivery) do
  order!
  route!
  delivery_list!(fabricator: :delivery_list_with_associations)
  package!
end

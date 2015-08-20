Fabricator(:delivery) do
  status "pending"
  order
  delivery_list
  delivery_service
  package
end

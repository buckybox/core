Fabricator(:delivery_list) do
  distributor
  date { Date.current - 1.day }
end

Fabricator(:delivery_list_with_associations, from: :delivery_list) do
  distributor!
  date { Date.current - 1.day }
end

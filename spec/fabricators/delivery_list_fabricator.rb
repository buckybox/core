Fabricator(:delivery_list) do
  distributor!
  date Date.current - 1.day
end

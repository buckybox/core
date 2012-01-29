Fabricator(:delivery_list) do
  distributor!
  date Date.today - 1.day
end
